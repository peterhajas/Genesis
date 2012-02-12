import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
import socket

from tornado.ioloop import IOLoop
from tornado import gen

from genesis.networking import Client, with_args, Communication
from genesis.serializers import BackendProtocol, NetworkSerializer
from genesis.data import NetOp, Account
from genesis.shell import ShellProxy, ProcessQuery


from Queue import Queue


class ResultCapture(object):
    def __init__(self, ioloop):
        self.responses = Queue()
        self.ioloop = ioloop

    @gen.engine
    def invoke(self, func, *args, **kwargs):
        response = yield gen.Task(func, *args, **kwargs)
        print 'got:', response
        self.responses.put(response)

    def pop(self):
        return self.responses.get_nowait()


cap = ResultCapture(IOLoop.instance())

@gen.engine
def interactive_handler(ios, mediator):
    # for pdb
    ios = ios
    mediator = mediator
    invoke = cap.invoke
    pop = cap.pop
    s = mediator.stream.socket

    import pdb; pdb.set_trace()
    ios.wait(interactive_handler, ios, mediator)


class iOSHandler(object):
    "Simulates the protocol that the iOS client would use."
    def __init__(self, account, machine, autoregister=False, delegate=None):
        self.account, self.machine = account, machine
        self.autoregister = autoregister
        self.delegate = delegate

    @gen.engine
    def handshake(self, mclient):
        # register
        if self.autoregister:
            response = yield gen.Task(mclient.register, self.account)
            if response.name != 'OK' and response['code'] != ErrorCodes.USERNAME_TAKEN:
                # quit
                print "Failed to register:", response['reason']
                mclient.close()
                raise StopIteration

        # login
        response = yield gen.Task(mclient.login, self.account, self.machine, type='iOS')
        print 'mediator ->', response
        if response.name != 'OK':
            print "Failed to login:", response['reason']
            raise StopIteration

        self.delegate(self, mclient)

    def wait(self, callback, *args, **kwargs):
        fn = lambda: callback(*args, **kwargs)
        mclient.io_loop.add_callback(fn)

    def get_builder(self, mclient, callback=None):
        def _handler(response):
            builder_name = None
            for name, kind in response['clients'].items():
                if kind == 'builder':
                    builder_name = name
                    break
            callback(name)
        mclient.clients(_handler)

    def read_stream(self, mclient, callback=None):
        print 'waiting for stream...'
        # then start accepting commands
        mclient.set_message_handler(self.recv_stream, callback=callback)

    @gen.engine
    def recv_message(self, mclient, message, callback=None):
        if message.name == 'STREAM':
            sys.stdout.write(message['contents'].replace('\n', '\n%s: ' % message['project']))
            sys.stdout.flush()
        elif message.name == 'STREAM_EOF':
            sys.stdout.write('\nEOF')
            sys.stdout.flush()
        elif message.name == 'RETURN':
            sys.stdout.write('%s return Code: %d' % (message['project'], message['code']))
            mclient.clear_message_handler()
            print "clear_message_handler()"
            if callable(callback):
                callback()
        else:
            raise TypeError("Unknown message to handle: " + repr(message))


class BuilderDelegate(object):
    "Handles the system commands to run"
    def __init__(self, account, machine, autoregister=False, shell_proxy=None):
        self.actions = {} # name => Action
        self.account = account
        self.machine = machine
        self.should_register = autoregister
        self.shell = shell_proxy or ShellProxy()

    def add_action(self, name, action):
        self.actions[name] = action

    def _send_op(self, ops, mclient, stream, callback):
        mclient.send(stream, op.to_network(), callback)

    @gen.engine
    def handshake(self, mclient):
        # register
        if self.should_register:
            print 'registering'
            response = yield gen.Task(mclient.register, self.account)
            if response.name != 'OK' and response['code'] != ErrorCodes.USERNAME_TAKEN:
                # quit
                print "Failed to register:", response['reason']
                mclient.close()
                raise StopIteration

        # login
        response = yield gen.Task(mclient.login, self.account, self.machine, type='builder')
        print 'mediator ->', response
        if response.name != 'OK':
            print "Failed to login:", response['reason']
            raise StopIteration

        print 'waiting for commands...'
        # then start accepting commands
        mclient.set_message_handler(self.process_request)

    @gen.engine
    def process_request(self, mclient, request):
        print 'mediator ->', request
        # dispatch
        method = getattr(self, 'do_' + request.name, None)
        if callable(method):
            method(mclient, request)
        else:
            yield gen.Task(mclient.send_response, NetOp(
                'FAIL',
                reason="Malformed request",
                code=ErrorCodes.BAD_REQUEST))

    @gen.engine
    def do_PROJECTS(self, mclient, request):
        yield gen.Task(mclient.send_response, NetOp(
            'OK',
            projects=[]
        ).to_network())

    def do_DOWNLOAD(self, mclient, request):
        project = request['project']
        filepath = request['filepath']
        print 'do download'

    def do_UPLOAD(self, mclient, request):
        print 'do upload'

    def do_FILES(self, mclient, request):
        project = request['project']
        print 'do files'

    def do_STATS(self, mclient, request):
        print 'do stats'

    def do_GIT(self, mclient, request):
        print 'do git'

    def do_CANCEL(self, mclient, request):
        print 'do cancel'

    def do_INPUT(self, mclient, request):
        print 'do input'

    def do_PERFORM(self, mclient, request):
        print 'do perform'
        return
        try:
            operation = ProcessQuery(self.shell.perform(self.actions[command.name]))
            while not operation.has_terminated():
                if operation.readable():
                    op = NetOp('stream', contents=operation.read())
                    mclient.send(stream, op.to_network(), callback)
        except KeyError:
            op = NetOp('bad_request')
            mclient.send(stream, op.to_network(), callback)



class MediatorClient(Communication):
    "Handles the communication between the builder and mediator."
    def __init__(self, client, serializer, delegate=None):
        super(MediatorClient, self).__init__(serializer)
        self.client = client
        self.delegate = delegate
        self.mediator_version = None

    def create(self, io_loop=None):
        self.client.create(self.handshake, io_loop)
        self.io_loop = self.client.io_loop

    def login(self, account, machine, type='builder', callback=None):
        "Logs into a given account, with specific machine credentials."
        cmd = NetOp('LOGIN',
                user=account.username,
                pwd=account.password_hash,
                machine=machine,
                type=type)
        self.request(self.stream, cmd.to_network(), callback)
        print 'mediator <-', cmd

    def register(self, account, callback=None):
        "Registers an account with the mediator server."
        cmd = NetOp('REGISTER', user=account.username, pwd=account.password)
        self.request(self.stream, cmd.to_network(), callback)
        print 'mediator <-', cmd

    def send_message(self, machine, command, callback):
        "Sends a given command to a target machine."
        if callable(getattr(command, 'to_network', None)):
            command = command.to_network()

        cmd = NetOp('SEND', machine=machine, command=command)
        self.request(self.stream, cmd.to_network(), callback)
        print 'mediator <-', cmd

    def send_response(self, command, callback):
        "Sends a given command back as a response."
        if not callable(getattr(command, 'to_network', None)):
            command = NetOp.create(command)
        self.send(self.stream, command.to_network(), callback)
        print "mediator <-", command

    def clients(self, callback=None):
        "Returns all clients connected using the given account."
        cmd = NetOp('CLIENTS')
        self.request(self.stream, cmd.to_network(), callback)
        print 'mediator <-', cmd

    def set_message_handler(self, handler, *args, **kwargs):
        """Assigns a given function as the message handler.

        Function should accept MediatorClient instance and NetOp instance.
        """
        def _on_read(fd, events):
            if not self.stream.socket or self.stream.socket.fileno() != fd:
                return # do nothing
            def _handler_wrapper(msg):
                handler(self, msg, *args, **kwargs)
            self.recv(self.stream, callback=_handler_wrapper)

        self.io_loop.add_handler(self.stream.socket.fileno(), _on_read, IOLoop.READ)

    def clear_message_handler(self):
        if not self.stream.closed():
            self.io_loop.remove_handler(self.stream.socket.fileno())

    def _accept_handshake(self, callback):
        self.serializer.accept_handshake(self.stream, callback)

    @gen.engine
    def handshake(self, stream):
        self.stream = stream
        # read version
        response = yield gen.Task(self._accept_handshake)
        self.mediator_version = response['version']
        print "Protocol Version:", self.mediator_version

        if not response['is_supported_version']:
            raise IOError("Unsupported version of server. Update builder? (got: %d; expected: %d)" % (
                self.mediator_version, self.serializer.version,
            ))

        self.delegate.handshake(self)

    def close(self, stop_ioloop=True):
        "Closes the client connection."
        if not self.stream.closed():
            self.io_loop.remove_handler(self.stream.socket.fileno())
        self.stream.close()
        if stop_ioloop:
            self.io_loop.stop()


if __name__ == '__main__':
    client = Client(port=8080, host='localhost')
    if 'client' in sys.argv:
        handler = iOSHandler(Account.create('jeff', 'password'), machine='TestClient', delegate=interactive_handler)
    else:
        handler = BuilderDelegate(Account.create('jeff', 'password'), machine='Builder1')
    mclient = MediatorClient(client, BackendProtocol(NetworkSerializer()), handler)
    mclient.create()
    #stream = client.create(send_response)
    IOLoop.instance().start()



import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
import socket

from tornado.ioloop import IOLoop
from tornado import gen

from genesis.utils import with_args
from genesis.networking import Client, MessageStream
from genesis.serializers import ProtocolSerializer, NetworkSerializer
from genesis.data import Message, Account
from genesis.shell import ShellProxy, ProcessQuery


from Queue import Queue


@gen.engine
def sample_handler(ios, mediator):
    response = yield gen.Task(mediator.clients)
    if response.name != 'OK':
        print "Failed to get clients connected."
        return mediator.close()

    if not response['clients'] or len(response['clients']) < 2:
        print "No other clients. Can't do anything."
        return mediator.close()

    builder = response['clients'].keys()[0]

    response = yield gen.Task(mediator.send, builder, Message('PROJECTS'))
    print 'mediator ->', response
    if not response['projects']:
        print "No projects found... quitting."
        return mediator.close()

    # just use the first project
    project_name = response['projects'][0]

    # get files
    response = yield gen.Task(
            mediator.send, builder, Message('FILES', project=project_name))
    print 'mediator ->', response
    if not response['files'] or len(response['files']) < 2:
        print "No files. Can't download anything."
        return mediator.close()

    filepath = response['files'].keys()[0]

    # download a file
    response = yield gen.Task(
            mediator.send, builder, Message('DOWNLOAD', filepath=filepath))
    print 'mediator ->', response
    if response.name != 'OK':
        print "Failed to download file!"

    # upload file???
    response = yield gen.Task(
            mediator.send, builder,
            Message('UPLOAD', filepath=filepath, data="print 'hello'"))
    print 'mediator ->', response
    if response.name != 'OK':
        print "Failed to upload file!"

    # perform action
    response = yield gen.Task(
            mediator.send, builder,
            Message('PERFORM', stream_to=ios.machine, project=project_name,
                action="run"))
    if response.name != 'OK':
        print "Failed to perform action 'run'..."
        mediator.close()

    yield gen.Task(mediator.


class MediatorClientDelegateBase(object):
    def __init__(self, account, machine, autoregister=False):
        self.account = account
        self.machine = machine
        self.should_register = autoregister

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

        self.handle(mclient)

    def handle(self, mclient):
        raise NotImplementedError("process_requets is not implemented")


class iOSHandler(MediatorClientDelegateBase):
    "Simulates the protocol that the iOS client would use."
    def __init__(self, account, machine, autoregister=False, io_loop=None, delegate=None):
        super(iOSHandler, self).__init__(account, machine, autoregister)
        self.io_loop = io_loop
        self.delegate = delegate

    def handle(self, mclient):
        self.delegate(self, mclient)

    def wait(self, callback, *args, **kwargs):
        fn = lambda: callback(*args, **kwargs)
        self.io_loop.add_callback(fn)

    def get_builder(self, mclient, callback=None):
        def _handler(response):
            builder_name = None
            for name, kind in response['clients'].items():
                if kind == 'builder':
                    builder_name = name
                    break
            callback(name)
        mclient.clients(_handler)

    def read_stream(self, mclient, on_stream, on_eof, on_return):
        print 'waiting for stream...'
        # then start accepting commands
        mclient.set_message_handler(self.recv_message, mclient,
                on_stream, on_eof, on_return)

    @gen.engine
    def recv_message(self, message, mclient, on_stream, on_eof, on_return):
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


class BuilderDelegate(MediatorClientDelegateBase):
    "Handles the system commands to run"
    def __init__(self, account, machine, autoregister=False, shell_proxy=None):
        super(BuilderDelegate, self).__init__(account, machine, autoregister)
        self.actions = {} # name => Action
        self.shell = shell_proxy or ShellProxy()

    def add_action(self, name, action):
        self.actions[name] = action

    @gen.engine
    def handle(self, mclient):
        print 'waiting for commands...'
        # then start accepting commands
        mclient.set_message_handler(self.handle_message, mclient)

    @gen.engine
    def handle_message(self, request, mclient):
        print 'mediator ->', request
        # dispatch
        method = getattr(self, 'do_' + request.name, None)
        if callable(method):
            method(mclient, request)
        else:
            yield gen.Task(mclient.send_response, Message(
                'FAIL',
                reason="Malformed request",
                code=ErrorCodes.BAD_REQUEST))

    @gen.engine
    def do_PROJECTS(self, mclient, request):
        yield gen.Task(mclient.write_response, Message(
            'OK',
            ACK=request.name,
            projects=[],
        ))

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
                    op = Message('stream', contents=operation.read())
                    mclient.write(op, callback)
        except KeyError:
            op = Message('bad_request')
            mclient.write(op, callback)



class MediatorClient(object):
    "Handles the communication between the builder and mediator."
    def __init__(self, client, serializer, delegate=None):
        self.serializer = serializer
        self.client = client
        self.delegate = delegate
        self.mediator_version = None
        self.stream = None

    def write(self, msg, callback=None):
        self.stream.write(msg, callback=None)

    def read(self, callback=None):
        self.stream.read(callback=callback)

    def create(self, io_loop=None):
        self.client.create(self.handshake, io_loop)
        self.io_loop = self.client.io_loop

    def login(self, account, machine, type='builder', callback=None):
        "Logs into a given account, with specific machine credentials."
        cmd = Message('LOGIN',
                user=account.username,
                pwd=account.password_hash,
                machine=machine,
                type=type)
        self.stream.write_and_read(cmd, callback=callback)
        print 'mediator <-', cmd

    def register(self, account, callback=None):
        "Registers an account with the mediator server."
        cmd = Message('REGISTER', user=account.username, pwd=account.password)
        self.stream.write_and_read(cmd, callback=callback)
        print 'mediator <-', cmd

    def send(self, machine, command, callback=None):
        "Sends a given message to a target machine."
        if callable(getattr(command, 'to_network', None)):
            command = command.to_network()

        cmd = Message('SEND', machine=machine, command=command)
        self.stream.write_and_read(cmd, callback=callback)
        print 'mediator <-', cmd

    def write_response(self, command, callback):
        "Sends a given command back as a response."
        if not callable(getattr(command, 'to_network', None)):
            command = Message.create(command)
        self.stream.write(command, callback=callback)
        print "mediator <-", command

    def clients(self, callback=None):
        "Returns all clients connected using the given account."
        cmd = Message('CLIENTS')
        self.stream.write_and_read(cmd, callback=callback)
        print 'mediator <-', cmd

    def set_message_handler(self, handler, *args, **kwargs):
        """Assigns a given function as the message handler.

        Function should accept MediatorClient instance and Message instance.
        """
        def _on_read(stream):
            stream.read(callback=with_args(handler, *args, **kwargs))

        self.stream.set_read_callback(_on_read)

    def clear_message_handler(self):
        self.stream.remove_callbacks()

    def _accept_handshake(self, callback):
        self.serializer.accept_handshake(self.stream.iostream(), callback=callback)

    @gen.engine
    def handshake(self, stream):
        self.stream = MessageStream(stream, self.serializer, self.io_loop)
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
        self.stream.close()
        if stop_ioloop:
            self.io_loop.stop()


if __name__ == '__main__':
    client = Client(port=8080, host='localhost')
    if 'client' in sys.argv:
        handler = iOSHandler(
                Account.create('jeff', 'password'),
                machine='TestClient',
                io_loop=IOLoop.instance(),
                delegate=sample_handler#interactive_handler
            )
    else:
        handler = BuilderDelegate(
                Account.create('jeff', 'password'),
                machine='Builder1')
    mclient = MediatorClient(client, ProtocolSerializer(NetworkSerializer()), handler)
    mclient.create()
    #stream = client.create(send_response)
    IOLoop.instance().start()



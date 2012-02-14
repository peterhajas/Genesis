import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
import socket

from tornado.ioloop import IOLoop
from tornado import gen

from genesis.utils import with_args
from genesis.networking import Client, MessageStream
from genesis.serializers import ProtocolSerializer, NetworkSerializer
from genesis.data import (Account, LoginMessage, ProjectsMessage, FilesMessage,
        DownloadMessage, UploadMessage, DownloadMessage, PerformMessage,
        StreamNotification, StreamEOFNotification, ReturnCodeNotification,
        ResponseMessage, RequestMessage, RegisterMessage, ClientsMessage,
        SendMessage, ErrorCodes
    )
from genesis.shell import ShellProxy, ProcessQuery


from Queue import Queue


@gen.engine
def sample_handler(ios, mediator):
    # get clients
    response = yield gen.Task(mediator.clients)
    if response.is_error:
        print "Failed to get clients connected."
        mediator.close()
        raise StopIteration

    if not response['clients'] or len(response['clients']) < 2:
        print "No other clients. Can't do anything."
        mediator.close()
        raise StopIteration

    # get a builder
    builders = [name for name, kind in response['clients'].items() if kind.startswith('builder')]
    if not builders:
        print "No builders!"
        mediator.close()
        raise StopIteration
    non_self_builders = [name for name in builders if name != ios.machine]
    builder = non_self_builders[0]

    # get builder's projects
    response = yield gen.Task(mediator.request, builder, ProjectsMessage())
    print 'mediator ->', response
    if not response['projects']:
        print "No projects found... quitting."
        mediator.close()
        raise StopIteration

    # just use the first project
    project_name = response['projects'][0]

    # get files for that project
    response = yield gen.Task(
            mediator.request, builder, FilesMessage(project=project_name))
    print 'mediator ->', response
    if not response['files'] or len(response['files']) < 1:
        print "No files. Can't download anything."
        mediator.close()
        raise StopIteration

    # use first file in the project
    filepath = response['files'][0]['name']

    # download it
    response = yield gen.Task(
            mediator.request, builder, DownloadMessage(filepath=filepath))
    print 'mediator ->', response
    if response.is_error:
        print "Failed to download file!"

    # upload changes
    response = yield gen.Task(
            mediator.request, builder,
            UploadMessage(filepath=filepath,
                data="print 'hello'",
                mimetype="plain/text"))
    print 'mediator ->', response
    if response.is_error:
        print "Failed to upload file!"

    # run it
    response = yield gen.Task(
            mediator.request, builder,
            PerformMessage(project=project_name, action="run"))
    if response.is_error:
        print "Failed to perform action 'run'..."
        mediator.close()
        raise StopIteration

    # get the stream results
    def on_stream(message):
        sys.stdout.write(message['contents'].replace('\n', '\n%s: ' % message['project']))
        sys.stdout.flush()

    def on_eof(message):
        sys.stdout.write('\nEOF\n')
        sys.stdout.flush()

    def on_return(message):
        print '%s return Code: %d' % (message['project'], message['code'])

    response = yield gen.Task(ios.read_stream, mclient, on_stream, on_eof, on_return)
    print "mediator ->", response

    # TODO: git push

    # done
    mediator.close()


class MediatorClientDelegateBase(object):
    def __init__(self, account, machine, autoregister=False, kind='builder'):
        self.account = account
        self.machine = machine
        self.should_register = autoregister
        self.kind = kind

    @gen.engine
    def handshake(self, mclient):
        # register
        if self.should_register:
            print 'registering'
            response = yield gen.Task(mclient.register, self.account)
            if response.is_error and response['code'] != ErrorCodes.USERNAME_TAKEN:
                # quit
                print "Failed to register:", response['reason']
                mclient.close()
                raise StopIteration

        # login
        response = yield gen.Task(mclient.login, self.account, self.machine, type=self.kind)
        print 'mediator ->', response
        if response.is_error:
            print "Failed to login:", response['reason']
            raise StopIteration

        self.handle(mclient)

    def handle(self, mclient):
        raise NotImplementedError("process_requets is not implemented")


class iOSHandler(MediatorClientDelegateBase):
    "Simulates the protocol that the iOS client would use."
    def __init__(self, account, machine, autoregister=False, io_loop=None, delegate=None):
        super(iOSHandler, self).__init__(account, machine, autoregister, kind='editor.ios')
        self.io_loop = io_loop
        self.delegate = delegate

    def handle(self, mclient):
        self.delegate(self, mclient)

    def wait(self, callback, *args, **kwargs):
        fn = lambda: callback(*args, **kwargs)
        self.io_loop.add_callback(fn)

    @gen.engine
    def read_stream(self, mclient, on_stream=None, on_eof=None, on_return=None, on_error=None, callback=None):
        print 'waiting for stream ...'
        def invoke(fn, message):
            if callable(fn):
                fn(message)
        while 1:
            message = yield gen.Task(mclient.read)
            if message.name == StreamNotification.name:
                invoke(on_stream, message)
            elif message.name == StreamEOFNotification.name:
                invoke(on_eof, message)
            elif message.name == ReturnCodeNotification.name:
                invoke(on_return, message)
                invoke(callback, message)
                raise StopIteration
            else:
                invoke(on_error, message)
                invoke(callback, message)
                if not callable(on_error) and not callable(callback):
                    raise TypeError("Unknown message to handle: " + repr(message))
                raise StopIteration



class BuilderDelegate(MediatorClientDelegateBase):
    "Handles the system commands to run"
    def __init__(self, account, machine, autoregister=False, shell_proxy=None):
        super(BuilderDelegate, self).__init__(account, machine, autoregister)
        self.actions = {} # name => Action
        self.shell = shell_proxy or ShellProxy()
        self.activity = None

    def add_action(self, name, action):
        self.actions[name] = action

    @gen.engine
    def handle(self, mclient):
        print 'waiting for commands...'
        # then start accepting commands
        while 1:
            message = yield gen.Task(mclient.read)
            self.handle_message(message, mclient)

    @gen.engine
    def handle_message(self, message, mclient):
        print 'mediator ->', message
        # dispatch
        if message.is_response and message.id in self.inbox:
            self.inbox[message.id]()
            del self.inbox[message.id]
        elif message.is_invocation:
            method = getattr(self, 'do_' + message.name, None)
            if callable(method):
                print 'invoking', 'do_' + message.name
                method(mclient, message)
        else:
            yield gen.Task(mclient.write_response,
                    ResponseMessage.error(message.id,
                        reason="Malformed request",
                        code=ErrorCodes.BAD_REQUEST))

    @gen.engine
    def do_projects(self, mclient, request):
        yield gen.Task(mclient.write_response,
                ResponseMessage.success(request.id, projects=[{"name": "project1"}]))

    @gen.engine
    def do_download(self, mclient, request):
        print 'do download', request
        yield gen.Task(mclient.write_response, ResponseMessage.success(
            request.id,
            data='print "hello"',
        ))

    @gen.engine
    def do_upload(self, mclient, request):
        # no op for now
        yield gen.Task(mclient.write_response, ResponseMessage.success(request.id))

    @gen.engine
    def do_files(self, mclient, request):
        project = request['project']
        yield gen.Task(mclient.write_response, ResponseMessage.success(
            request.id,
            files=[{
                "name": "foo.py",
                "size": 123,
                "kind": "source",
                "mimetype": "plain/text",
            }],
        ))

    @gen.engine
    def do_stats(self, mclient, request):
        yield gen.Task(mclient.write_response, ResponseMessage.success(
            request.id,
            activity=self.activity,
        ))

    @gen.engine
    def do_git(self, mclient, request):
        print 'do git'

    @gen.engine
    def do_cancel(self, mclient, request):
        print 'do cancel'

    @gen.engine
    def do_input(self, mclient, request):
        print 'do input'

    @gen.engine
    def do_perform(self, mclient, request):
        target = request.sender
        name = request['project']
        yield gen.Task(mclient.write_response, ResponseMessage.success(request.id))
        yield gen.Task(mclient.send, target, StreamNotification(
            project=name,
            contents='foobar',
        ))
        yield gen.Task(mclient.send, target, StreamEOFNotification(
            project=name,
        ))
        yield gen.Task(mclient.send, target, ReturnCodeNotification(
            project=name,
            code=0
        ))
        raise StopIteration
        try:
            operation = ProcessQuery(self.shell.perform(self.actions[command.name]))
            while not operation.has_terminated():
                if operation.readable():
                    op = StreamNotification(contents=operation.read())
                    mclient.write(op, callback)
        except KeyError:
            op = ResponseMessage.error(request.id, reason='bad_request')
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
        cmd = LoginMessage(username=account.username,
                password=account.password_hash,
                machine=machine,
                type=type)
        self.stream.write_and_read(cmd, callback=callback)
        print 'mediator <-', cmd

    def register(self, account, callback=None):
        "Registers an account with the mediator server."
        cmd = RegisterMessage(account.username, account.password)
        self.stream.write_and_read(cmd, callback=callback)
        print 'mediator <-', cmd

    def send(self, machine, command, callback=None):
        "sends a given message to a target machine. Expects no response from target."
        if callable(getattr(command, 'to_network', None)):
            command = command.to_network()

        cmd = SendMessage(machine=machine, command=command)
        self.stream.write(cmd, callback=callback)
        print 'mediator <-', cmd

    def request(self, machine, command, callback=None):
        "Sends a given message to a target machine. Expects a response from target."
        if callable(getattr(command, 'to_network', None)):
            command = command.to_network()

        cmd = RequestMessage(machine=machine, command=command)
        self.stream.write_and_read(cmd, callback=callback)
        print 'mediator <-', cmd

    def write_response(self, command, callback):
        "Sends a given command back as a response."
        if not callable(getattr(command, 'to_network', None)):
            command = ResponseMessage.create(command)
        self.stream.write(command, callback=callback)
        print "mediator <-", command

    def clients(self, callback=None):
        "Returns all clients connected using the given account."
        cmd = ClientsMessage()
        self.stream.write_and_read(cmd, callback=callback)
        print 'mediator <-', cmd

    def _accept_handshake(self, callback):
        self.serializer.accept_handshake(self.stream.iostream(), callback=callback)

    @gen.engine
    def handshake(self, stream):
        self.stream = MessageStream(stream, self.serializer, self.io_loop)
        # read version
        print 'waiting for version'
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



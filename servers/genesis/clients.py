import time
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from Queue import Queue

from tornado.ioloop import IOLoop
from tornado import gen

from genesis.utils import with_args, platform
from genesis.networking import Client, MessageStream
from genesis.serializers import ProtocolSerializer, NetworkSerializer
from genesis.data import (Account, LoginMessage, ProjectsMessage, FilesMessage,
        DownloadMessage, UploadMessage, DownloadMessage, PerformMessage,
        StreamNotification, StreamEOFNotification, ReturnCodeNotification,
        ResponseMessage, RequestMessage, RegisterMessage, ClientsMessage,
        CancelMessage, SendMessage, ErrorCodes
    )
from genesis.builder import Builder


# an example set of commands an iOS client would send
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

    print "Using builder", builder

    # get builder's projects
    response = yield gen.Task(mediator.request, builder, ProjectsMessage())
    if not response['projects']:
        print "No projects found... quitting."
        mediator.close()
        raise StopIteration

    # just use the first project
    project_name = response['projects'][0]
    print "Using project", project_name

    # get files for that project
    response = yield gen.Task(
            mediator.request, builder, FilesMessage(project=project_name))
    if not response['files'] or len(response['files']) < 1:
        print "No files. Can't download anything."
        mediator.close()
        raise StopIteration

    # use first file in the project
    filepath = response['files'][0]['name']
    print "Download file", filepath

    # download it
    response = yield gen.Task(
            mediator.request, builder, DownloadMessage(project_name, filepath))
    if response.is_error:
        print "Failed to download file!"
        mediator.close()
        raise StopIteration

    # upload changes
    response = yield gen.Task(
            mediator.request, builder,
            UploadMessage(project_name, filepath, contents="print 'hello'"))
    if response.is_error:
        print "Failed to upload file!"
        mediator.close()
        raise StopIteration

    # run it
    response = yield gen.Task(
            mediator.request, builder,
            PerformMessage(project=project_name, action="test"))
    if response.is_error:
        print "Failed to perform action 'run'..."
        mediator.close()
        raise StopIteration

    # get the stream results
    def on_stream(message):
        sys.stdout.write(message['contents'])
        sys.stdout.flush()

    def on_eof(message):
        sys.stdout.write('\nEOF\n')
        sys.stdout.flush()

    def on_return(message):
        print '%s return Code: %d' % (message['project'], message['code'])

    response = yield gen.Task(ios.read_stream, mclient, on_stream, on_eof, on_return)

    # TODO: git push

    # done
    mediator.close()


class MediatorClientDelegateBase(object):
    def __init__(self, account, machine, kind, autoregister=False, io_loop=None):
        self.account = account
        self.machine = machine
        self.should_register = autoregister
        self.kind = kind
        self.io_loop = io_loop or IOLoop.instance()

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
        if response.is_error:
            print "Failed to login:", response['reason']
            mclient.close()
            raise StopIteration

        self.handle(mclient)


    def handle(self, mclient):
        raise NotImplementedError("handle heeds to be implemented by subclass")

    def wait(self, callback, *args, **kwargs):
        fn = lambda: callback(*args, **kwargs)
        self.io_loop.add_callback(fn)

    def wait_for(self, seconds, callback, *args, **kwargs):
        fn = lambda: callback(*args, **kwargs)
        self.io_loop.add_timeout(seconds, fn)

def request_requires(key, reason, code, mclient_index=0, request_index=1, validator=lambda v: v):
    def decorator(fn):
        @gen.engine
        def wrapped(self, *args, **kwargs):
            mclient = args[mclient_index]
            request = args[request_index]
            if not validator(self, request[key]):
                yield gen.Task(mclient.write_response, ResponseMessage.error(
                    request.id,
                    reason=reason,
                    code=code,
                ))
                raise StopIteration
            fn(self, *args, **kwargs)

        return wrapped
    return decorator


class iOSHandler(MediatorClientDelegateBase):
    "Simulates the protocol that the iOS client would use."
    def __init__(self, account, machine, autoregister=False, delegate=None, io_loop=None):
        kind = 'editor.genesis.test.%s' % platform
        super(iOSHandler, self).__init__(account, machine, kind, autoregister, io_loop=io_loop)
        self.delegate = delegate

    def handle(self, mclient):
        self.delegate(self, mclient)

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
    def __init__(self, account, builder, machine=None, autoregister=False, io_loop=None):
        self.builder = builder
        self.process_query = None
        kind = 'builder.genesis.%s' % platform()
        super(BuilderDelegate, self).__init__(
                account,
                machine or self.builder.name or 'Unnamed machine',
                kind,
                autoregister,
                io_loop)

    @gen.engine
    def handle(self, mclient):
        print 'waiting for commands...'
        # then start accepting commands
        while 1:
            message = yield gen.Task(mclient.read)
            self.handle_message(message, mclient)

    @gen.engine
    def handle_message(self, message, mclient):
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
                ResponseMessage.success(request.id,
                    projects=self.builder.project_names))

    def _invalid_project(self, mclient, request, callback=None):
        if request['project'] not in self.builder.project_names:
            mclient.write_response(ResponseMessage.error(
                request.id,
                reason="Invalid Project",
                code=ErrorCodes.MISSING_PROJECT,
            ), callback=callback)
            return True
        return False

    @gen.engine
    def do_download(self, mclient, request):
        if self._invalid_project(mclient, request):
            raise StopIteration

        if not self.builder.has_file(request['project'], request['filepath']):
            yield gen.Task(mclient.write_response, ResponseMessage.error(
                request.id,
                reason="Invalid filepath",
                code=ErrorCodes.MISSING_FILEPATH,
            ))
            raise StopIteration
        contents = self.builder.read_file(request['project'], request['filepath'])
        if contents is None:
            yield gen.Task(mclient.write_response, ResponseMessage.error(
                request.id,
                reason="Invalid filepath",
                code=ErrorCodes.MISSING_FILEPATH,
            ))
            raise StopIteration
        yield gen.Task(mclient.write_response, ResponseMessage.success(
            request.id,
            project=request['project'],
            filepath=request['filepath'],
            contents=contents,
        ))

    @gen.engine
    def do_upload(self, mclient, request):
        if self._invalid_project(mclient, request):
            raise StopIteration

        if request['contents'] is None:
            yield gen.Task(mclient.write_response, ResponseMessage.error(
                request.id,
                reason="Bad Request",
                code=ErrorCodes.BAD_REQUEST,
            ))
            raise StopIteration
        # no op for now
        try:
            self.builder.write_file(request['project'], request['filepath'], request['contents'] or '')
        except IOError:
            yield gen.Task(mclient.write_response, ResponseMessage.error(
                request.id, reason="Failed to write", code=ErrorCodes.INTERNAL_ERROR))
            raise StopIteration

        yield gen.Task(mclient.write_response, ResponseMessage.success(request.id))

    @gen.engine
    def do_files(self, mclient, request):
        if self._invalid_project(mclient, request):
            raise StopIteration

        yield gen.Task(mclient.write_response, ResponseMessage.success(
            request.id,
            files=self.builder.get_files(request['project']),
        ))

    @gen.engine
    def do_stats(self, mclient, request):
        yield gen.Task(mclient.write_response, ResponseMessage.success(
            request.id,
            activity=self.builder.activities,
        ))

    @gen.engine
    def do_git(self, mclient, request):
        yield gen.Task(mclient.write_response, ResponseMessage.error(
            request.id,
            reason="Not yet supported.",
            code=ErrorCodes.INTERNAL_ERROR,
        ))

    @gen.engine
    def do_cancel(self, mclient, request):
        if self._invalid_project(mclient, request):
            raise StopIteration

        if not self.process_query:
            yield gen.Task(mclient.write_response, ResponseMessage.error(
                request.id,
                reason="No process running for %r." % request['project']
            ))
            raise StopIteration

        self.process_query.terminate()
        yield gen.Task(mclient.write_response, ResponseMessage.success(request.id))

        # really kill it if we need to
        yield gen.Task(mclient.wait_for, seconds=1)
        self.process_query.kill()
        self.process_query = None

    @gen.engine
    def do_input(self, mclient, request):
        if self._invalid_project(mclient, request):
            raise StopIteration

        if request['contents'] is None:
            yield gen.Task(mclient.write_response, ResponseMessage.error(
                request.id,
                reason="Bad Request",
                code=ErrorCodes.BAD_REQUEST,
            ))
            raise StopIteration

        if not self.process_query:
            yield gen.Task(mclient.write_response, ResponseMessage.error(
                request.id,
                reason="No process running for %r." % request['project'],
                code=ErrorCodes.NO_ACTIVITY,
            ))
            raise StopIteration

        self.process_query.write(str(request['contents']))
        yield gen.Task(mclient.write_response, ResponseMessage.success(request.id))

    @gen.engine
    def do_perform(self, mclient, request):
        if self._invalid_project(mclient, request):
            raise StopIteration
        project = self.builder.projects[request['project']]

        if project.is_busy:
            yield gen.Task(mclient.write_response, ResponseMessage.error(
                request.id,
                reason="Project is busy. Use cancel to stop existing command.",
                code=ErrorCodes.ACTION_CONFLICT,
            ))
            raise StopIteration

        if request['action'] not in project.actions:
            yield gen.Task(mclient.write_response, ResponseMessage.error(
                request.id,
                reason="Invalid Action",
                code=ErrorCodes.MISSING_ACTION,
            ))
            raise StopIteration

        self.process_query = project.perform_action(request['action'])

        target = request.sender
        yield gen.Task(mclient.write_response, ResponseMessage.success(request.id))

        # TODO: handle stdin
        while not self.process_query.has_terminated or self.process_query.can_read:
            if self.process_query.can_read:
                yield gen.Task(mclient.send, target, StreamNotification(
                    project=project.name,
                    contents=self.process_query.read(),
                ))
            else:
               # wait, to allow processing of other IO
               yield gen.Task(self.wait)

        yield gen.Task(mclient.send, target, StreamEOFNotification(
            project=project.name,
        ))
        yield gen.Task(mclient.send, target, ReturnCodeNotification(
            project=project.name,
            code=self.process_query.return_code,
        ))
        self.process_query = None



class MediatorClient(object):
    "Handles the communication between the builder and mediator."
    def __init__(self, client, serializer, delegate=None, autoreconnect=True):
        self.serializer = serializer
        self.client = client
        self.delegate = delegate
        self.mediator_version = None
        self.stream = None
        self.wants_to_close = False
        self.autoreconnect = autoreconnect

    def write(self, msg, callback=None):
        self.stream.write(msg, callback=None)

    def read(self, callback=None):
        self.stream.read(callback=callback)

    def create(self, io_loop=None):
        self.client.create(self.handshake, self.on_close, io_loop)
        self.io_loop = self.client.io_loop

    def login(self, account, machine, type='builder', callback=None):
        "Logs into a given account, with specific machine credentials."
        cmd = LoginMessage(username=account.username,
                password=account.password_hash,
                machine=machine,
                type=type)
        self.stream.write_and_read(cmd, callback=callback)

    def register(self, account, callback=None):
        "Registers an account with the mediator server."
        cmd = RegisterMessage(account.username, account.password)
        self.stream.write_and_read(cmd, callback=callback)

    def send(self, machine, command, callback=None):
        "sends a given message to a target machine. Expects no response from target."
        if callable(getattr(command, 'to_network', None)):
            command = command.to_network()

        cmd = SendMessage(machine=machine, command=command)
        self.stream.write(cmd, callback=callback)

    def request(self, machine, command, callback=None):
        "Sends a given message to a target machine. Expects a response from target."
        if callable(getattr(command, 'to_network', None)):
            command = command.to_network()

        cmd = RequestMessage(machine=machine, command=command)
        self.stream.write_and_read(cmd, callback=callback)

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

    def _accept_handshake(self, callback):
        self.serializer.accept_handshake(self.stream.iostream, callback=callback)

    @gen.engine
    def handshake(self, stream):
        self.stream = MessageStream(stream, self.serializer, self.io_loop)
        self.stream.set_close_callback(self.on_close)
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


    def on_close(self):
        if self.wants_to_close:
            return # continue
        if self.autoreconnect:
            if self.client.is_connected:
                print "Connection lost. Reconnecting..."
            self.create()

    def close(self, stop_ioloop=True):
        "Closes the client connection."
        self.wants_to_close = True
        self.stream.close()
        if stop_ioloop:
            self.io_loop.stop()


if __name__ == '__main__':
    import random
    if 'client' in sys.argv:
        handler = iOSHandler(
                Account.create('jeff', 'password'),
                machine='TestClient' + str(random.random()),
                delegate=sample_handler,#interactive_handler
            )
        port, host = int(sys.argv[2]), sys.argv[3] if len(sys.argv) >= 4 else 'localhost'
        client = Client(port=port, host=host)
    else:
        builder = Builder.from_file('./sample_config.yml')
        handler = BuilderDelegate(Account.create('jeff', 'password'), builder)
        port, host = builder.port, builder.host
        client = Client(port=builder.port, host=builder.host)
    mclient = MediatorClient(client, ProtocolSerializer(NetworkSerializer()), handler)
    mclient.create()
    #stream = client.create(send_response)
    print "Connecting to %s:%d" % (host, port)
    IOLoop.instance().start()



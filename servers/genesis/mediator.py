import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from tornado.ioloop import IOLoop
from tornado import iostream, gen

from genesis.networking import Server, MessageStream
from genesis.serializers import ProtocolSerializer, NetworkSerializer
from genesis.data import (ErrorCodes, Account, ResponseMessage, LoginMessage,
        invocation_message, get_message_class, InvocationMessage, RegisterMessage)


class ClientHandler(object):
    "Handles the management of a client's incoming messages."
    def __init__(self, message_stream, address, tracker):
        self.namespace = self.machine = self.type = None
        self.stream = message_stream
        self.address = address
        self.tracker = tracker
        self.account = None
        self.reroute = []

    def __repr__(self):
        return "ClientHandler<%s @ %s>" % (self.id, self.address)

    @property
    def id(self):
        if self.namespace and self.type and self.machine:
            return "%s.%s.%s" % (self.namespace, self.type, self.machine)
        return self.address_str()

    def full_name(self):
        return "%s.%s.%s" % (self.namespace, self.type, self.machine)

    def address_str(self):
        return self.address[0] + ':' + str(self.address[1])

    def fail(self, id, **kwargs):
        close = kwargs.pop('close_stream', False)
        msg = ResponseMessage.error(id, **kwargs)
        if close:
            print self.id, '<-', msg, '+ close'
        else:
            print self.id, '<-', msg
        closefn = lambda: self.tracker.remove(self)
        self.stream.write(msg, callback=closefn if close else None)

    def close(self):
        print "Disconnected", self.full_name(), '-', self.address_str()
        self.stream.close()

    @gen.engine
    def handle_register(self, request):
        "Register a new user account fo this client."
        # TODO: use real db?
        if request['user'] == 'jeff' and request['pwd'] == 'pass':
            pass

    @gen.engine
    def handle_login(self, request):
        "Log this client in."
        request = request.cast_to(LoginMessage)
        self.account = Account(request['username'], request['password'])
        # TODO: use real db?
        if self.account == Account.create('jeff', 'password'):
            # TODO: verify machine & type values
            self.machine, self.type = request['machine'], request['type']
            self.namespace = request['username']
            print self.address_str(), "=>", self.id
            if not self.tracker.assign_namespace(self):
                yield gen.Task(self.stream.write, ResponseMessage.error(
                    request.id,
                    reason="Machine of name %r already connected." % self.machine,
                    code=ErrorCodes.MACHINE_CONFLICT
                ))
                self.close()
                raise StopIteration
            msg = ResponseMessage.success(request.id)
            yield gen.Task(self.stream.write, msg)
            print self.id, '<-', msg
            self.process_request()
        else:
            self.fail(request.id, code=ErrorCodes.BAD_AUTH, close_stream=False)

    @gen.engine
    def handshake(self):
        # make this method the primary handling method unless otherwise
        # noted
        while not self.account:
            request = yield gen.Task(self.stream.read)
            print self.id, '->', request.name
            if request.name == RegisterMessage.name:
                self.handle_register(request)
            elif request.name == LoginMessage.name:
                self.handle_login(request)
            else:
                self.fail(request.id, code=ErrorCodes.BAD_REQUEST)

    @gen.engine
    def process_request(self):
        while 1:
            message = yield gen.Task(self.stream.read)
            print self.id, '->', message
            if message.is_response and self.reroute:
                index = -1
                for i, (req_msg, callback) in enumerate(self.reroute):
                    if req_msg.id == message.id:
                        index = i
                        break
                if index < 0:
                    print "Ignoring invalid request", message,
                    continue
                _, callback = self.reroute.pop(index)
                print "Got message:", message
                callback(message)
            elif message.is_invocation:
                method = getattr(self, 'do_' + message.name, None)
                if callable(method):
                    method(message)
                else:
                    print "Failed to find method:", 'do_' + message.name
            else:
                print "UNKNOWN MESSAGE:", message

    @gen.engine
    def do_clients(self, request):
        machines = {}
        for name, client in self.tracker.get_namespace(self.namespace).items():
            machines[name] = client.type
        msg = ResponseMessage.success(request.id, clients=machines)
        print self.id, '<-', msg
        yield gen.Task(self.stream.write, msg)

    @gen.engine
    def do_request(self, request):
        # TODO: reject if sender or command is malformed
        print 'REQUEST: namespace =', self.namespace, '; machine =', request['machine']
        target = self.tracker.get_client_in_namespace(self.namespace, request['machine'])
        if target is None:
            print "No machine named:", request['machine']
            msg = ResponseMessage.error(request.id,
                    reason="No machine exists named %r" % request['machine'],
                    code=ErrorCodes.UNKNOWN_MACHINE)
            yield gen.Task(self.stream.write, msg)
            raise StopIteration
        msg = InvocationMessage.create(request['command'])
        if not msg:
            print "bad message:", repr(msg)
            raise StopIteration
        msg.sender = self.machine
        print target.id, '<-', msg.name, '[forwarding]'
        response = yield gen.Task(target.request, msg)
        print '[forwarding]', target.id, '->', response
        response.sender = target.machine
        print self.id, '<-', response, '[forwarding]'
        yield gen.Task(self.stream.write, response)

    @gen.engine
    def do_send(self, request, callback=None):
        # TODO: reject if sender or command is malformed
        target = self.tracker.get_client_in_namespace(self.namespace, request['machine'])
        if target is None:
            # absorb all invalid messages
            print "No machine named:", request['machine'], '... Ignoring message'
            raise StopIteration
        msg = InvocationMessage.create(request['command'])
        if not msg:
            print repr(request)
            print "bad message:", repr(msg)
            raise StopIteration
        msg.sender = self.machine
        print target.id, '<-', msg.name, '[forwarding]'
        yield gen.Task(target.stream.write, msg)
        if callable(callback):
            callback()

    def request(self, msg, callback=None):
        "Perform a send & add expected response to routing list."
        self.reroute.append((msg, callback))
        self.stream.write(msg)


class ClientsTracker(object):
    """"Keeps track of all active connections.
    Allows clients to pipe data to each other.
    """
    def __init__(self):
        self.namespaces = {} # str => {str => Client}
        self.clients = {} # ip => Client

    def __contains__(self, address):
        return address in self.clients

    def add(self, client):
        self.clients[client.address] = client

    def remove(self, client):
        if client.address in self.clients:
            self.unassign_namespace(client)
            del self.clients[client.address]
            client.close()

    def remove_by_addr(self, address):
        if address in self.clients:
            client = self.get(address)
            self.unassign_namespace(client)
            del self.clients[address]
            client.close()

    def get(self, address):
        return self.clients[address]

    def get_namespace(self, name):
        return self.namespaces[name]

    def get_client_in_namespace(self, name, machine):
        return self.namespaces.get(name, {}).get(machine)

    def has_namespace(self, name):
        return name in self.namespaces

    def assign_namespace(self, client):
        if not self.has_namespace(client.namespace):
            self.namespaces[client.namespace] = {}
        if not self.get_client_in_namespace(client.namespace, client.machine):
            self.namespaces[client.namespace][client.machine] = client
            return True
        return False

    def unassign_namespace(self, client):
        if not self.has_namespace(client.namespace): return
        if client.machine not in self.namespaces[client.namespace]: return
        if client != self.namespaces[client.namespace][client.machine]: return
        del self.namespaces[client.namespace][client.machine]


class Mediator(object):
    "Manages the accepting incoming connections."
    def __init__(self, serializer, io_loop=None):
        self.serializer = serializer
        self.io_loop = io_loop or IOLoop.instance()
        self.tracker = ClientsTracker()

    def on_close(self, address):
        self.tracker.remove_by_addr(address)

    def send_version(self, stream, callback):
        stream.write(self.serializer.offer_handshake(), callback)

    @gen.engine
    def handle_stream(self, stream, address, server):
        print 'Connection from', address

        # send version
        yield gen.Task(self.send_version, stream)

        msg_stream = MessageStream(stream, self.serializer, self.io_loop)
        client = ClientHandler(msg_stream, address, self.tracker)
        self.tracker.add(client)
        client.handshake()


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print "Usage: %s PORT [HOST]" % sys.argv[0]
        sys.exit(1)
    port = int(sys.argv[1])
    host = sys.argv[2] if len(sys.argv) > 2 else ''
    mediator = Mediator(ProtocolSerializer(NetworkSerializer()))
    server = Server(mediator, port=port, host=host)
    server.start()
    IOLoop.instance().start()


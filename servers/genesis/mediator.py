import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from tornado.ioloop import IOLoop
from tornado import iostream, gen

from genesis.networking import Server, Communication
from genesis.serializers import BackendProtocol, NetworkSerializer
from genesis.data import NetOp, ErrorCodes


class ClientHandler(Communication):
    "Handles the management of a client's incoming messages."
    def __init__(self, io_loop, stream, address, tracker, serializer):
        super(ClientHandler, self).__init__(serializer)
        self.namespace = self.machine = self.type = None
        self.io_loop = io_loop
        self.stream = stream
        self.address = address
        self.tracker = tracker

    @property
    def id(self):
        if self.namespace and self.type and self.machine:
            return "%s.%s.%s" % (self.namespace, self.type, self.machine)
        return self.address_str()

    def full_name(self):
        return "%s.%s.%s" % (self.namespace, self.type, self.machine)

    def address_str(self):
        return self.address[0] + ':' + str(self.address[1])

    def fail(self, **properties):
        close = properties.pop('close_stream', False)
        cmd = NetOp('FAIL', **properties)
        if close:
            print self.id, '<-', cmd, '+ close'
        else:
            print self.id, '<-', cmd
        closefn = lambda: self.tracker.remove(self)
        self.send(self.stream, cmd.to_network(),
                callback=closefn if close else None)

    def close(self):
        print "Disconnected", self.full_name(), '-', self.address_str()
        if not self.stream.closed():
            self.io_loop.remove_handler(self.stream.socket.fileno())
        self.stream.close()

    def handle_register(self, request):
        "Register a new user account fo this client."
        # TODO: use real db?
        if request['user'] == 'jeff' and request['pwd'] == 'pass':
            pass

    def handle_login(self, request):
        "Log this client in."
        # TODO: use real db?
        if request['user'] == 'jeff' and request['pwd'] == 'pass':
            # TODO: verify machine & type values
            self.machine, self.type = request['machine'], request['type']
            self.namespace = request['user']
            print self.address_str(), "=>", self.id
            self.tracker.assign_namespace(self)
            self.send(self.stream, NetOp('OK').to_network(), callback=None)
            # add handler overwrites existing handlers
            self.io_loop.add_handler(
                    self.stream.socket.fileno(),
                    self.process_request,
                    IOLoop.READ)
        else:
            self.fail(code=ErrorCodes.BAD_AUTH, close_stream=False)

    @gen.engine
    def handshake(self):
        # make this method the primary handling method unless otherwise
        # noted
        self.io_loop.add_handler(
                self.stream.socket.fileno(), self.handshake, IOLoop.READ)

        request = yield gen.Task(self.recv, self.stream)
        print self.id, '->', request
        if request.name == 'REGISTER':
            self.handle_register(request)
        elif request.name == 'LOGIN':
            self.handle_login(request)
        else:
            self.fail(code=ErrorCodes.BAD_REQUEST)

    @gen.engine
    def process_request(self, fd, events):
        request = yield gen.Task(self.recv, self.stream)
        print self.id, '->', request
        method = getattr(self, 'do_' + request.name, None)
        if callable(method):
            method(request)

    @gen.engine
    def do_CLIENTS(self, request):
        machines = {}
        for name, client in self.tracker.get_namespace(self.namespace).items():
            machines[name] = client.type
        msg = NetOp('OK', clients=machines)
        print self.id, '<-', msg
        yield gen.Task(self.send, self.stream, msg.to_network())

    @gen.engine
    def do_SEND(self, request):
        # TODO: reject if from_machine or command is malformed
        target = self.tracker.get_client_in_namespace(self.namespace, self.machine)
        msg = NetOp.create(request['command'])
        msg['from'] = self.machine
        print target.id, '<-', msg
        response = yield gen.Task(target.request, target.stream, msg.to_network())
        print target.id, '->', response
        response['from'] = target.machine
        print self.id, '<-', response
        yield gen.Task(self.send, self.stream, response.to_network())


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
        return self.namespaces[name][machine]

    def has_namespace(self, name):
        return name in self.namespaces

    def assign_namespace(self, client):
        if not self.has_namespace(client.namespace):
            self.namespaces[client.namespace] = {}
        self.namespaces[client.namespace][client.machine] = client

    def unassign_namespace(self, client):
        if self.has_namespace(client.namespace): return
        if client.machine not in self.namespaces[client.namespace]: return
        if client != self.namespaces[client.namespace][client.machine]: return
        del self.namespaces[client.namespace][client.machine]


class Mediator(Communication):
    "Manages the accepting incoming connections."
    def __init__(self, serializer, io_loop=None):
        super(Mediator, self).__init__(serializer)
        self.io_loop = io_loop or IOLoop.instance()
        self.tracker = ClientsTracker()

    def on_close(self, address):
        self.tracker.remove_by_addr(address)

    @gen.engine
    def handle_stream(self, stream, address, server):
        print 'Connection from', address

        # send version
        yield gen.Task(self.send_version, stream)

        client = ClientHandler(
                self.io_loop, stream, address, self.tracker, self.serializer)
        self.tracker.add(client)
        client.handshake()


if __name__ == '__main__':
    mediator = Mediator(BackendProtocol(NetworkSerializer()))
    server = Server(mediator, port=8080, host='localhost')
    server.start()
    IOLoop.instance().start()


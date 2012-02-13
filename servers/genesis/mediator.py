import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from tornado.ioloop import IOLoop
from tornado import iostream, gen

from genesis.networking import Server, MessageStream
from genesis.serializers import ProtocolSerializer, NetworkSerializer
from genesis.data import Message, ErrorCodes, Account


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

    def fail(self, **properties):
        close = properties.pop('close_stream', False)
        cmd = Message('FAIL', **properties)
        if close:
            print self.id, '<-', cmd, '+ close'
        else:
            print self.id, '<-', cmd
        closefn = lambda: self.tracker.remove(self)
        self.stream.write(cmd, callback=closefn if close else None)

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
        self.account = Account(request['user'], request['pwd'])
        # TODO: use real db?
        if self.account == Account.create('jeff', 'password'):
            # TODO: verify machine & type values
            self.machine, self.type = request['machine'], request['type']
            self.namespace = request['user']
            print self.address_str(), "=>", self.id
            self.tracker.assign_namespace(self)
            msg = Message('OK')
            yield gen.Task(self.stream.write, msg)
            print self.id, '<-', msg
            # add handler overwrites existing handlers
            self.accepts_requests()
        else:
            self.fail(code=ErrorCodes.BAD_AUTH, close_stream=False)

    def accepts_requests(self, enabled=True):
        self.stream.set_read_callback(self.process_request if enabled else None)


    @gen.engine
    def handshake(self):
        # make this method the primary handling method unless otherwise
        # noted
        self.stream.set_read_callback(self.handshake)

        request = yield gen.Task(self.stream.read)
        print self.id, '->', request
        if request.name == 'REGISTER':
            self.handle_register(request)
        elif request.name == 'LOGIN':
            print "LOGIN"
            self.handle_login(request)
        else:
            self.fail(code=ErrorCodes.BAD_REQUEST)

    CALLBACKS = ('OK', 'FAIL')
    def process_request(self, stream):
        if stream.reading():
            print 'process_request', self
            import sys
            sys.exit(1)
        print 'incoming request from', self.id
        def _callback(request):
            print self.id, '->', request
            method = getattr(self, 'do_' + request.name, None)
            if callable(method):
                method(request)
            elif request.name in self.CALLBACKS and self.reroute:
                index = -1
                for i, (target, orig, callback) in enumerate(self.reroute):
                    if orig.name == request['ACK']:
                        index = i
                        break;
                if index < 0:
                    print "Ignoring invalid request", request,
                    return
                target, orig, callback = self.reroute.pop(index)
                m = Message('SEND', command=orig, machine=target)
                print "Got message:", request
                callback(request)
        self.stream.read(callback=_callback)

    @gen.engine
    def do_CLIENTS(self, request):
        machines = {}
        for name, client in self.tracker.get_namespace(self.namespace).items():
            machines[name] = client.type
        msg = Message('OK', clients=machines)
        print self.id, '<-', msg
        yield gen.Task(self.stream.write, msg)

    @gen.engine
    def do_REQUEST(self, request, is_return=False):
        # TODO: reject if sender or command is malformed
        print 'namespace =', self.namespace, '; machine =', request['machine']
        target = self.tracker.get_client_in_namespace(self.namespace, request['machine'])
        if target is None:
            print "No machine named:", request['machine']
            msg = Message('FAIL',
                    reason="No machine exists named %r" % request['machine'],
                    code=ErrorCodes.UNKNOWN_MACHINE)
            yield gen.Task(self.stream.write, msg)
        msg = Message.create(request['command'])
        if not msg:
            print "bad message:", repr(msg)
            return
        msg['sender'] = self.machine
        print target.id, '<-', msg, '[forwarding]'
        response = yield gen.Task(target.request, self.machine, msg)
        print '[forwarding]', target.id, '->', response
        response['sender'] = target.machine
        print self.id, '<-', response, '[forwarding]'
        yield gen.Task(self.stream.write, response)

    @gen.engine
    def do_SEND(self, request, is_return=False):
        # TODO: reject if sender or command is malformed
        print 'namespace =', self.namespace, '; machine =', request['machine']
        target = self.tracker.get_client_in_namespace(self.namespace, request['machine'])
        if target is None:
            print "No machine named:", request['machine']
            msg = Message('FAIL',
                    reason="No machine exists named %r" % request['machine'],
                    code=ErrorCodes.UNKNOWN_MACHINE)
            yield gen.Task(self.stream.write, msg)
        msg = Message.create(request['command'])
        if not msg:
            print "bad message:", repr(msg)
            return
        msg['sender'] = self.machine
        print target.id, '<-', msg, '[forwarding]'
        yield gen.Task(target.stream.write, msg)

    def request(self, original, msg, callback=None):
        "Perform a send & add expected response to routing list."
        self.reroute.append((original, msg, callback))
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
        self.namespaces[client.namespace][client.machine] = client

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
    mediator = Mediator(ProtocolSerializer(NetworkSerializer()))
    server = Server(mediator, port=8080, host='localhost')
    server.start()
    IOLoop.instance().start()


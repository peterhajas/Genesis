import errno
import socket
from functools import partial

from tornado.ioloop import IOLoop
from tornado import iostream


def accept_connection(handler, wrap_socket=None):
    def connection_handler(sock, fd, events):
        while 1:
            try:
                connection, address = sock.accept()
            except socket.error, e:
                if e.args[0] not in (errno.EWOULDBLOCK, errno.EAGAIN):
                    raise
                return
            connection.setblocking(0)
            if wrap_socket:
                connection = wrap_socket(connection)
            handler(connection, address)
    return connection_handler

def with_args(callback, *args, **kwargs):
    def handler(*a, **k):
        a += args
        kwargs.update(k)
        callback(*a, **kwargs)
    return handler


class Client(object):
    def __init__(self, port, host='', family=socket.AF_INET, kind=socket.SOCK_STREAM):
        self.port = port
        self.host = host
        self.family = family
        self.kind = kind
        self.sock = None
        self.stream = None

    def create(self, callback=None, ioloop=None):
        ioloop = ioloop or IOLoop.instance()
        self.sock, self.stream = self._create_socket_and_stream()

        callback_partial = None
        if callable(callback):
            callback_partial = partial(callback, self.stream)

        self.stream.connect((self.host, self.port), callback_partial)
        return self.stream

    def _create_socket_and_stream(self):
        "Creates a non-blocking client socket to listen on the given hostname and port."
        sock = socket.socket(self.family, self.kind)
        sock.setblocking(0)
        stream = iostream.IOStream(sock)
        return sock, stream


class Server(object):
    def __init__(self, port, host='', family=socket.AF_INET, kind=socket.SOCK_STREAM, backlog=128):
        self.port = port
        self.host = host
        self.family = family
        self.kind = kind
        self.backlog = backlog
        self.handlers = []
        self.sock = None

    def add_handler(self, handler, events=IOLoop.READ):
        self.handlers.append((handler, events))

    def create(self, ioloop=None):
        ioloop = ioloop or IOLoop.instance()
        self.sock = self._create_socket()
        for handler, events in self.handlers:
            partial_handler = partial(handler, self.sock)
            ioloop.add_handler(self.sock.fileno(), partial_handler, events)
        return self

    def _create_socket(self):
        "Creates a non-blocking server socket to listen on the given hostname and port."
        sock = socket.socket(self.family, self.kind)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.setblocking(0)
        sock.bind((self.host, self.port))
        sock.listen(self.backlog)
        if self.host:
            print "Listening on %s:%s" % (self.host, self.port)
        else:
            print "Listening on port %s" % self.port
        return sock

class Communication(object):
    def __init__(self, serializer):
        self.serializer = serializer

    def send(self, stream, data, callback):
        "Sends the given message"
        data = self.serializer.serialize(data)
        stream.write(data, callback)

    def recv(self, stream, callback):
        "Receives a given message."
        self.serializer.deserialize(stream, callback)

    def send_and_recv(self, stream, data, callback):
        "Sends a message and expects a response."
        def recieve():
            self.serializer.deserialize(stream, callback)
        self.send(stream, data, recieve)


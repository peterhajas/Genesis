import errno
import socket
import ssl
from functools import partial

from tornado.ioloop import IOLoop
from tornado import iostream, gen

from genesis.data import NetOp


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
    def __init__(self, delegate, port, host='', family=socket.AF_INET, kind=socket.SOCK_STREAM, backlog=128, ssl_options=None, io_loop=None):
        self.port = port
        self.host = host
        self.family = family
        self.kind = kind
        self.backlog = backlog
        self.sock = None
        self.ssl_options = ssl_options
        self.delegate = delegate
        self.io_loop = io_loop or IOLoop.instance()

        self.clients = {} # address => stream

    def add_handler(self, handler, events=IOLoop.READ):
        self.handlers.append((handler, events))

    def _on_close(self, address):
        def on_close():
            if address in self.clients:
                self.delegate.on_close(address)
                self.clients[address].close()
                del self.clients[address]
        return on_close

    def accept_connections(self, fd, events):
        while 1:
            try:
                connection, address = self.sock.accept()
            except socket.error, e:
                if e.args[0] not in (errno.EWOULDBLOCK, errno.EAGAIN):
                    raise
                return
            connection.setblocking(0)
            stream = self.create_stream(connection, address)
            stream.set_close_callback(self._on_close(address))
            if stream:
                self.clients[address] = stream
                self.delegate.handle_stream(stream, address, self)
            else:
                print "Rejected", address, "- could not create stream"

    def create_stream(self, connection, address):
        # taken from TCPServer of tornado
        if self.ssl_options is not None:
            assert ssl, "Python 2.6+ and OpenSSL required for SSL"
            try:
                connection = ssl.wrap_socket(
                        connection,
                        server_side=True,
                        do_handshake_on_connect=False,
                        **self.ssl_options)
            except ssl.SSLError, err:
                if err.args[0] == ssl.SSL_ERROR_EOF:
                    return connection.close()
                else:
                    raise
            except socket.error, err:
                if err.args[0] == errno.ECONNABORTED:
                    return connection.close()
                else:
                    raise
        try:
            if self.ssl_options is not None:
                stream = iostream.SSLIOStream(connection, io_loop=self.io_loop)
            else:
                stream = iostream.IOStream(connection, io_loop=self.io_loop)
        except Exception:
            raise
        return stream

    def start(self):
        self.sock = self._create_socket()
        self.io_loop.add_handler(self.sock.fileno(), self.accept_connections, IOLoop.READ)
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
    def __init__(self, serializer, autoconvert=True):
        self.serializer = serializer
        self.autoconvert = autoconvert

    def send(self, stream, data, callback):
        "Sends the given message"
        data = self.serializer.serialize(data)
        stream.write(data, callback)

    def _to_netop(self, callback):
        def handler(raw_msg):
            callback(NetOp.create(raw_msg))
        return handler

    def recv(self, stream, callback):
        "Receives a given message."
        if self.autoconvert:
            self.serializer.deserialize(stream, self._to_netop(callback))
        else:
            self.serializer.deserialize(stream, callback)

    def request(self, stream, data, callback):
        "Sends a message and expects a response."
        def recieve():
            self.recv(stream, callback)
        self.send(stream, data, recieve)



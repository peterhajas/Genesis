import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from tornado.ioloop import IOLoop
from tornado import iostream, gen

from genesis.networking import Server, with_args, accept_connection, Communication
from genesis.serializers import BackendProtocol, NetworkSerializer


class Mediator(Communication):
    def __init__(self, serializer):
        super(Mediator, self).__init__(serializer)

    @gen.engine
    def __call__(self, stream, address):
        print 'got connection', stream, 'from', address
        data = yield gen.Task(self.recv, stream)
        print data
        yield gen.Task(self.send, stream, ['OK'])
        stream.close()

def echo_responder(data, stream):
    print 'writing response:', data
    stream.write(data)
    stream.close()

def echo_handler(stream, address):
    print "Connection Received:", stream, "from", address
    stream.read_until('\n', with_args(echo_responder, stream))

if __name__ == '__main__':
    server = Server(port=8080)
    mediator = Mediator(BackendProtocol(NetworkSerializer(compress_level=0)))
    server.add_handler(accept_connection(mediator, iostream.IOStream))
    server.create()
    IOLoop.instance().start()


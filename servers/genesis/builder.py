import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
import socket

from tornado.ioloop import IOLoop
from tornado import gen

from genesis.networking import Client, with_args, Communication
from genesis.serializers import BackendProtocol, NetworkSerializer


class MediatorClient(Communication):
    def __init__(self, client, serializer):
        super(MediatorClient, self).__init__(serializer)
        self.client = client

    def create(self, ioloop=None):
        self.client.create(self.handle_stream, ioloop)

    @gen.engine
    def handle_stream(self, stream):
        # authenticate
        #msg = Message(['LOGIN', 'MY_SYSTEM'])
        #print msg
        #yield gen.Task(msg, stream, self.serializer)
        #response = yield gen.Task(self.serializer.deserialize, stream)
        response = yield gen.Task(self.send_and_recv, stream, ['LOGIN', 'MYSYS'])
        print repr(response)
        stream.close()
        IOLoop.instance().stop()


def consume_result(data, stream):
    print data
    stream.close()
    IOLoop.instance().stop()


def read_response(stream):
    print 'reading'
    stream.read_until_close(with_args(consume_result, stream))


def send_response(stream):
    print 'starting response'
    stream.write('there is no spoon\n', with_args(read_response, stream))


if __name__ == '__main__':
    client = Client(port=8080)
    mclient = MediatorClient(client, BackendProtocol(NetworkSerializer(compress_level=0)))
    mclient.create()
    #stream = client.create(send_response)
    IOLoop.instance().start()



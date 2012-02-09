import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
import socket

from tornado.ioloop import IOLoop
from tornado import gen

from genesis.networking import Client, with_args, Communication
from genesis.serializers import BackendProtocol, NetworkSerializer
from genesis.data import NetOp
from genesis.shell import ShellProxy, ProcessQuery



class Builder(object):
    "Handles the system commands to run"
    def __init__(self, shell_proxy=None):
        self.actions = {} # name => Action
        self.shell = shell_proxy or ShellProxy()

    def add_action(self, name, action):
        self.actions[name] = action

    def _send_op(self, ops, mclient, stream, callback):
        mclient.send(stream, op.to_network(), callback)

    def __call__(self, command, mclient, stream, callback):
        try:
            operation = ProcessQuery(self.shell.perform(self.actions[command.name]))
            while not operation.has_terminated():
                if operation.readable():
                    op = NetOp('stream', contents=operation.read())
                    mclient.send(stream, op.to_network(), callback)
        except KeyError:
            op = NetOp('bad_request')
            mclient.send(stream, op.to_network(), callback)


class MediatorClient(Communication):
    "Handles the communication between the builder and mediator."
    def __init__(self, client, serializer, delegate=None):
        super(MediatorClient, self).__init__(serializer)
        self.client = client
        self.delegate = delegate

    def create(self, ioloop=None):
        self.client.create(self.handle_stream, ioloop)

    def handle_task(self, stream):
        pass

    @gen.engine
    def handle_stream(self, stream):
        # read version
        version = yield gen.Task(stream.read_until, ' ')
        print "Protocol Version:", version
        # authenticate
        cmd = NetOp('LOGIN', user='jeff', pwd='pass', machine='foobar', type='builder')
        response = yield gen.Task(self.request, stream, cmd.to_network())
        print 'login:', response
        if not response.name == 'OK':
            print 'Invalid login'
            stream.close()
            return

        cmd = NetOp('CLIENTS')
        clients = yield gen.Task(self.request, stream, cmd.to_network())
        print 'clients:', clients

        while 1:
            data = yield gen.Task(self.recv, stream)
            command = Command.create(data)
            # invalid
            if not command:
                print "[IGNORE] invalid command:", repr(data)
                continue

            if not self.delegate:
                print "[PASSIVE] no delegate:", command
                continue

            yield self.delegate(command, self, stream)

        # terminate
        stream.close()
        IOLoop.instance().stop()


if __name__ == '__main__':
    client = Client(port=8080, host='localhost')
    mclient = MediatorClient(client, BackendProtocol(NetworkSerializer()))
    mclient.create()
    #stream = client.create(send_response)
    IOLoop.instance().start()



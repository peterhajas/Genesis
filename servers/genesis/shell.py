import shlex
import subprocess
import os
import sys
import Queue as queue
from threading import Thread


def is_windows():
    return sys.platform == 'win32'


# see:
# http://stackoverflow.com/questions/375427/non-blocking-read-on-a-subprocess-pipe-in-python
class ProcessQuery(object):
    "Represents an interface to query a subprocess."
    def __init__(self, process):
        self.process = process
        self.queue = queue.Queue()
        self.thread_out = self._create_thread(
            target=self._fill_output, args=(p.stdout, self.queue))
        self.thread_err = self._create_thread(
            target=self._fill_output, args=(p.stderr, self.queue))

    def _create_thread(self, target, args):
        t = Thread(target=target, args=args)
        # thread dies with the program
        t.daemon = True
        t.start()
        return t

    def _fill_output(self, stream, queue):
        # TODO: read by char instead of by line
        for line in iter(stream.readline, ''):
            queue.put(line)
        stream.close()

    def has_terminated(self):
        return self.process.poll() is None

    def return_code(self):
        return self.process.returncode

    def readable(self):
        return not self.queue.empty()

    def write(self, data):
        "Writes data to stdin"
        self.process.stdin.write(data)

    def read(self):
        try:
            return self.queue.get_nowait()
        except queue.Empty:
            return None


class ShellProxy(object):
    "Represent shell commands to run."
    def __init__(self, bufsize=None):
        self.bufsize = bufsize if bufsize is not None else 1024

    def run(self, command, input=None, cwd=None):
        # remember, shell=True is extremely dangerous.
        p = subprocess.Popen(
            command, cwd=cwd,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            shell=True, bufsize=self.bufsize)
        return p

    def perform(self, action):
        return self.run(action.command, action.input, action.cwd)



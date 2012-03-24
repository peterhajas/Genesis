import shlex
import subprocess
import os
import Queue as queue
from threading import Thread

from genesis.utils import is_windows


# see:
# http://stackoverflow.com/questions/375427/non-blocking-read-on-a-subprocess-pipe-in-python
class ProcessQuery(object):
    "Represents an interface to query a subprocess."
    def __init__(self, process):
        self.process = process
        self.queue = queue.Queue()
        self.thread_out = self._create_thread(
            target=self._fill_output, args=(process.stdout, self.queue))
        self.thread_err = self._create_thread(
            target=self._fill_output, args=(process.stderr, self.queue))

    def _create_thread(self, target, args):
        t = Thread(target=target, args=args)
        # thread dies with the program
        t.daemon = True
        t.start()
        return t

    def _fill_output(self, stream, queue):
        string = stream.read(1)
        while string:
            queue.put(string)
            string = stream.read(1)
        stream.close()

    @property
    def has_terminated(self):
        return self.process.poll() is not None

    @property
    def return_code(self):
        return self.process.poll()

    @property
    def can_read(self):
        return not self.queue.empty()

    def terminate(self):
        if not self.has_terminated:
            self.process.terminate()

    def kill(self):
        if not self.has_terminated:
            self.process.kill()

    def write(self, data):
        "Writes data to stdin"
        self.process.stdin.write(data)
        self.process.stdin.flush()

    def read(self):
        try:
            buff = []
            while not self.queue.empty():
                buff.append(self.queue.get_nowait())
            return ''.join(buff)
        except queue.Empty:
            return None


class ShellProxy(object):
    "Represent shell commands to run."
    def __init__(self, executable=None, sources=None, bufsize=None):
        self.bufsize = bufsize if bufsize is not None else 1024
        # TODO: validate executable path
        self.executable = executable or '/bin/bash'
        self.sources = list(sources or ['$HOME/.bashrc', '$HOME/.bash_profile'])

    def _build_command(self, command):
        # TODO: escape filenames?
        sources = [('source "%s"' % src) for src in self.sources]
        if sources:
            return '%s && (%s)' % (' || '.join(sources), command)
        return command

    def run(self, command, input=None, cwd=None):
        # remember, shell=True is extremely dangerous.
        p = subprocess.Popen(
            self._build_command(command), cwd=cwd,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            executable=self.executable, shell=True, bufsize=self.bufsize)
        return p

    def perform(self, action):
        return self.run(action.command, action.input, action.cwd)



import sys
import os

def with_args(callback, *args, **kwargs):
    def handler(*a, **k):
        a += args
        kwargs.update(k)
        callback(*a, **kwargs)
    return handler

def is_windows():
    return sys.platform == 'win32'

def expand(string):
    "Expands tilde and environment variables in the provided string."
    return os.path.expanduser(os.path.expandvars(string))


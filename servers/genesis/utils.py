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

def platform():
    if sys.platform.startswith('linux'):
        return 'Linux'
    return {
        'win32': 'Windows',
        'cygwin': 'Windows',
        'darwin': 'OSX',
    }.get(sys.platform, sys.platform)

def expand(string):
    "Expands tilde and environment variables in the provided string."
    return os.path.expanduser(os.path.expandvars(string))


import os
import hashlib


class Action(object):
    "Represents the shell commands that the builder performs."
    def __init__(self, command, input=None, cwd=None):
        self.cwd = cwd or os.getcwd()
        self.command = command
        self.input = input
        self.__environment = {} # additional environmental vars to set

    def __getitem__(self, key):
        return self.__environment[key]

    def get(self, key, default=None):
        return self.__environment.get(key, default)

    def __setitem__(self, key, value):
        self.__environment[key] = value

    def keys(self):
        return self.__environment.keys()

    def values(self):
        return self.__environment.values()

    def __iter__(self):
        return iter(self.__environment)


class ErrorCodes(object):
    # general purpose
    INTERNAL_ERROR, BAD_REQUEST = range(2)
    # for register
    USERNAME_TAKEN = 100
    INVALID_USERNAME = 101
    INVALID_PASSWORD = 102
    # for login
    BAD_AUTH = 100
    MACHINE_CONFLICT = 101
    INVALID_MACHINE = 102
    INVALID_TYPE = 103
    # for machine
    UNKNOWN_MACHINE = 100

class Account(object):
    "Represents a username and hashed password."
    HASH = hashlib.sha512
    def __init__(self, username, password_hash):
        self.username = username
        self.password_hash = password_hash

    @classmethod
    def create(cls, username, password):
        "Creates an instance with a raw password, hashing it in the process."
        hasher = cls.HASH()
        hasher.update(password)
        return cls(username, hasher.hexdigest())

    def __hash__(self):
        return hash(self.username) ^ (self.password_hash)

    def __eq__(self, account):
        return (self.username, self.password_hash) == (
                account.username, account.password_hash)


class Message(object):
    "Generate request or response used by either mediator or builder."
    def __init__(self, name,  **kwargs):
        self.name = name
        self.kwargs = kwargs

    def __getitem__(self, key):
        return self.kwargs.get(key)

    def __contains__(self, key):
        return key in self.kwargs

    def __setitem__(self, key, value):
        self.kwargs[key] = value

    def __iter__(self):
        return iter(self.kwargs)

    @classmethod
    def create(cls, obj):
        "Creates an instance of NetOp from a tuple or array. Returns None on failure."
        try:
            name, kwargs = obj
            assert isinstance(name, str) or isinstance(name, unicode)
            return cls(name, **kwargs)
        except:
            return None

    def __repr__(self):
        pairs = ["%s=%r" % (key, val) for key, val in self.kwargs.items()]
        args = pairs
        #args = list(map(repr, self.args)) + pairs
        return '%(name)s(%(args)s)' % {
            'name': self.name,
            'args': ', '.join(args),
        }

    def to_network(self):
        return [self.name, self.kwargs]


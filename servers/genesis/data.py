import os
import hashlib
import uuid


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
    INTERNAL_ERROR = 0
    BAD_REQUEST = 1
    # for register
    USERNAME_TAKEN = 100
    INVALID_USERNAME = 101
    INVALID_PASSWORD = 102
    # for login
    BAD_AUTH = 103
    MACHINE_CONFLICT = 104
    INVALID_MACHINE = 105
    INVALID_TYPE = 106
    # for send / request
    UNKNOWN_MACHINE = 107
    # for download
    MISSING_PROJECT = 108
    MISSING_FILEPATH = 109
    # for perform
    MISSING_ACTION = 110
    ACTION_CONFLICT = 111
    # for input and cancel
    NO_ACTIVITY = 112

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
        return hash(self.username) ^ hash(self.password_hash)

    def __eq__(self, account):
        return (self.username, self.password_hash) == (
                account.username, account.password_hash)

class InvocationMessage(object):
    "Represents a remote procedure call with an expected response."
    MAPPING = None
    REQUIRES_SENDER = False
    name = None
    is_invocation = True
    is_response = False
    is_notification = False
    def __init__(self, *args, **kwargs):
        self.id = self.__class__.create_id(kwargs.pop('id', None))
        self.sender = 0

        if self.MAPPING is None:
            self.args = list(args)
        else:
            self.args = [None] * len(self.MAPPING)
            for i, value in enumerate(args):
                self.args[i] = value
            for key, value in kwargs.items():
                try:
                    self.args[self.MAPPING.index(key)] = value
                except (IndexError, TypeError):
                    raise KeyError('%r is not a valid message parameter.' % key)

    def cast_to(self, cls):
        return cls.create(self.to_network())

    def __hash__(self):
        return hash(self.id) ^ hash(self.sender) ^ hash(tuple(self.args))

    def __eq__(self, other):
        return hash(self) == hash(other)

    def __index_for_name(self, name, default=None):
        try:
            return self.MAPPING.index(name)
        except (IndexError, TypeError, ValueError):
            return default

    def __getitem__(self, key):
        return self.args[self.__index_for_name(key, key)]

    def __setitem__(self, key, value):
        self.args[self.__index_for_name(key, key)] = value

    def __contains__(self, key):
        return self.__index_for_name(key, key) in self.args

    def __setitem__(self, key, value):
        self.args[self.__index_for_name(key, key)] = value

    def __reversemapping(self):
        return dict(map(reversed, self.MAPPING.items()))

    def __repr__(self):
        args = []
        for i, value in enumerate(self.args):
            if self.MAPPING is None:
                args.append(repr(value))
            elif 0 <= i < len(self.MAPPING):
                args.append("%s=%r" % (self.MAPPING[i], value))
            else:
                args.append(repr(value))
        return '%(name)s(%(args)s)<%(id)s, %(sender)r>' % {
            'name': self.name,
            'args': ', '.join(args),
            'id': self.id,
            'sender': self.sender,
        }

    @classmethod
    def create_id(cls, provided_id=None):
        "Defines the unique ID for this message."
        if provided_id is None:
            return str(uuid.uuid4())
        return str(provided_id)

    @classmethod
    def create(cls, dictionary):
        "Creates an instance of request from dictionary. Returns None on failure."
        try:
            assert isinstance(dictionary['method'], str) or isinstance(dictionary['method'], unicode)
            assert cls.name is None or dictionary['method'] == cls.name
            params = list(dictionary['params'])
            sender = params.pop()
            instance = cls(*params, id=dictionary['id'])
            instance.name = dictionary['method']
            instance.sender = sender
            return instance
        except (KeyError, AssertionError):
            return None

    def to_network(self):
        return {
            "method": self.name,
            "params": self.args + [self.sender],
            "id": self.id,
        }

class RegisterMessage(InvocationMessage):
    name = 'register'
    MAPPING = ('username', 'password')

class LoginMessage(InvocationMessage):
    name = 'login'
    MAPPING = ('username', 'password', 'machine', 'type')

class ProjectsMessage(InvocationMessage):
    name = 'projects'
    MAPPING = ()

class FilesMessage(InvocationMessage):
    name = 'files'
    MAPPING = ('project', 'branch',)

class BranchesMessage(InvocationMessage):
    name = 'branches'
    MAPPING = ('project',)

class DownloadMessage(InvocationMessage):
    name = 'download'
    MAPPING = ('project', 'filepath',)

class UploadMessage(InvocationMessage):
    name = 'upload'
    MAPPING = ('project', 'filepath', 'contents',)

class PerformMessage(InvocationMessage):
    name = 'perform'
    MAPPING = ('project', 'action')

class DiffStatsMessage(InvocationMessage):
    name = 'diff_stats'
    MAPPING = ('project',)

class StageFileMessage(InvocationMessage):
    name = 'stage_file'
    MAPPING = ('project', 'filepath')

class CommitMessage(InvocationMessage):
    name = 'commit'
    MAPPING = ('project', 'message')

class SendMessage(InvocationMessage):
    name = 'send'
    MAPPING = ('machine', 'command')

class RequestMessage(InvocationMessage):
    name = 'request'
    MAPPING = ('machine', 'command')

class CancelMessage(InvocationMessage):
    name = 'cancel'
    MAPPING = ('project',)

class InputMessage(InvocationMessage):
    name = 'input'
    MAPPING = ('project', 'contents')

class NotificationMessage(InvocationMessage):
    "Represents a remote procedure call with the expectation of NO response."
    is_invocation = True
    is_response = False
    is_notification = True
    @classmethod
    def create_id(cls, provided_id=None):
        return None

class StreamNotification(NotificationMessage):
    name = 'stream'
    MAPPING = ('project', 'contents',)

class StreamEOFNotification(NotificationMessage):
    name = 'stream_eof'
    MAPPING = ('project',)

class ReturnCodeNotification(NotificationMessage):
    name = 'return'
    MAPPING = ('project', 'code')

class ClientsMessage(InvocationMessage):
    name = 'clients'
    MAPPING = ()

class ResponseMessage(object):
    "The results of remotely invoking a given procedure."
    is_invocation = False
    is_response = True
    is_notification = False
    def __init__(self, id, result=None, error=None):
        assert result is not None or error is not None, "Both result and error cannot be None. (%r, %r)" % (result, error)
        self.id, self.result, self.error = id, result, error

    def __repr__(self):
        return "%(name)s(%(id)r, %(result)r, %(error)r)" % {
            "name": self.__class__.__name__,
            "id": self.id,
            "result": self.result,
            "error": self.error,
        }

    def __getitem__(self, key):
        if self.is_error:
            return self.error.get(key)
        return self.result.get(key)

    @property
    def is_error(self):
        "Returns true if the given response is an error message."
        return self.result is None and self.error is not None

    @classmethod
    def create(cls, dictionary):
        "Creates an instance of request from dictionary. Returns None on failure."
        try:
            return cls(dictionary['id'], dictionary['result'], dictionary['error'])
        except (KeyError, AssertionError):
            return None

    def to_network(self):
        return {
            "id": self.id,
            "result": self.result,
            "error": self.error,
        }

    @classmethod
    def error(cls, id, **kwargs):
        instance = cls(id, None, kwargs)
        instance.name = 'FAIL'
        return instance

    @classmethod
    def success(cls, id, **kwargs):
        instance = cls(id, kwargs, None)
        instance.name = 'OK'
        return instance


class Message(object):
    "Generate request or response used by either mediator or builder."
    def __init__(self, name, **kwargs):
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

# all the messages the parser can base
messages = [
    RegisterMessage, LoginMessage, ProjectsMessage, FilesMessage,
    DownloadMessage, UploadMessage, PerformMessage, SendMessage,
    RequestMessage, StreamNotification, StreamEOFNotification,
    BranchesMessage, ReturnCodeNotification, ClientsMessage,
]

def get_message_class(dictionary):
    instance = InvocationMessage.create(dictionary)
    if instance:
        for msg in messages:
            if instance.name == msg.name:
                return msg
    return None


def invocation_message(dictionary):
    klass = get_message_class(dictionary)
    if klass:
        return klass.create(dictionary)
    return None


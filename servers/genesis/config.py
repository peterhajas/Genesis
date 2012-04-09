import os
import yaml
import getpass

def load_yaml(filename):
    with open(filename, 'r') as handle:
        return yaml.load(handle.read())

def save_yaml(filename, obj):
    with open(filename, 'w+') as handle:
        handle.write(yaml.dump(obj))

def merge(d, **kwargs):
    """Recursively merges given kwargs int to a
    dict - only if the values are not None.
    """
    for key, value in kwargs.items():
        if isinstance(value, dict):
            d[key] = merge(d.get(key, {}), **value)
        elif value is not None:
            d[key] = value
    return d

def load_settings(filename, **kwargs):
    """Loads the settings file with some overridable values specified
    in kwargs.
    """
    filepath = os.path.abspath(os.path.join(os.getcwd(), filename))
    settings = {
        'username': getpass.getuser(),
        'mediator': {
            'host': 'localhost',
            'port': 7331,
        }
    }
    try:
        settings = merge(settings, **load_yaml(filepath))
    except IOError:
        print "Failed to load config file: %s" % filepath
        return None

    return merge(settings, **kwargs)


import random
import getpass
import sys
import argparse
import os

from tornado.ioloop import IOLoop

sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from genesis.clients import (
    EditorDelegate, BuilderDelegate, MediatorClient, sample_handler
)
from genesis.builder import Builder, BuilderConfig
from genesis.mediator import Mediator
from genesis.config import load_settings
from genesis.serializers import ProtocolSerializer, NetworkSerializer
from genesis.networking import Server, Client
from genesis.data import Account


def main(progn, *arguments):
    args = get_args(progn, arguments)
    addr, port = parse_address(args.ADDRESS)

    if args.type in ('builder', 'editor'):
        create_client(args.type, load_config(args, addr, port))
    elif args.type == 'mediator':
        create_mediator(addr or '', port or 7331)
    else:
        raise TypeError("Invalid command.")

    try:
        IOLoop.instance().start()
    except KeyboardInterrupt:
        print "Goodbye."

    return 0

def load_config(args, addr, port):
    settings = load_settings(
        args.config,
        mediator=dict(
            host=addr,
            port=port,
        ),
        username=args.user,
    )
    settings['__filepath__'] = args.config
    if 'password' not in settings:
        settings['password'] = getpass.getpass('Password: ')
    settings['mediator']['port'] = int(settings['mediator']['port'])
    return settings


# activation

def create_client(type, config):
    addr = config['mediator']['host']
    port = config['mediator']['port']
    print "Connecting to", address_to_str(addr, port), "..."

    if type == 'editor':
        delegate = EditorDelegate(
            Account.create(config['username'], config['password']),
            machine='TestiOSClient' + str(random.random()),
            delegate=sample_handler,
        )
    elif type == 'builder':
        builder = Builder(BuilderConfig(config, config['__filepath__']))
        delegate = BuilderDelegate(
            Account.create(config['username'], config['password']),
            builder=builder,
            machine=config['name']
        )
    else:
        raise TypeError("Invalid Type")

    client = Client(port, addr)
    mediator_client = MediatorClient(
        client, ProtocolSerializer(NetworkSerializer()), delegate)
    mediator_client.create()

def create_mediator(addr, port):
    print "Running MEDIATOR on", address_to_str(addr, port), "..."

    mediator = Mediator(ProtocolSerializer(NetworkSerializer()))
    server = Server(mediator, port=port, host=addr)
    server.start()

### PARSING ###

def address_to_str(addr, port):
    if addr:
        return "%s:%d" % (addr, port)
    else:
        return "%d" % port

def parse_address(string):
    """Parses the address and port number from the command line.
    Returns addres and port. Both can be None if config should be used instead.
    """
    if string is None:
        return None, None

    if ':' in string:
        addr, port = string.split(':')
        return addr, int(port)

    if '.' in string: # ip address
        return string, None

    return '', int(string) # port

def get_args(progn, args):
    "Parses the CLI arguments."
    parser = argparse.ArgumentParser(
        description="Runs the builder or mediator that is the underlying infastructure of Genesis.",
        prog=progn
    )

    # mediator
    subcommands = parser.add_subparsers(title='type', dest='type',
        description="How this program should behave in the Genesis network system.")
    mediator = subcommands.add_parser('mediator', help="Runs as a mediator server. The mediator facilitates communication between the Builder and the Editor.")
    mediator.add_argument('ADDRESS', default=None,
        help="The address to listen (Mediator) or connect to (Builder). In the format of ADDRESS:PORT, where either one can be optional. Overrides value from config for builder and editor.")

    # builder
    builder = subcommands.add_parser('builder', help="Runs the builder client, which connects to a mediator.")
    builder.add_argument('--username', '--user', default=None, dest='user',
        help="The username for the builder to use. This overrides the one defined in the config.")
    builder.add_argument('--password', '--pwd', '--pass', action='store_true',
        help="Prompt for the password for the builder to user. This override the one defined in the config.")
    builder.add_argument('--config', '-c', default='config.yml',
        help="The configuration file to use. Configuration values differ if running as a mediator server."
    )
    builder.add_argument('ADDRESS', default=None, nargs='?',
        help="The address to listen (Mediator) or connect to (Builder). In the format of ADDRESS:PORT, where either one can be optional. Overrides value from config for builder and editor.")

    # iOS test client
    editor = subcommands.add_parser('editor', help="Runs a simulated editor client, which connects to a mediator.")
    editor.add_argument('--username', '--user', default=None, dest='user',
        help="The username for the editor to use. This overrides the one defined in the config.")
    editor.add_argument('--password', '--pwd', '--pass', action='store_true',
        help="Prompt for the password for the editor to user. This override the one defined in the config.")
    editor.add_argument('--config', '-c', default='config.yml',
        help="The configuration file to use. Configuration values differ if running as a mediator server.")
    editor.add_argument('ADDRESS', default=None, nargs='?',
        help="The address to listen (Mediator) or connect to (Builder). In the format of ADDRESS:PORT, where either one can be optional. Overrides value from config for builder and editor.")

    return parser.parse_args(list(args))

if __name__ == '__main__':
    sys.exit(main(*sys.argv))

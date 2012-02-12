"""Classes that handle the serialization of containers, usually to pass over
the wire.

All data is represented as strings.
"""
import zlib
import json
import struct

from genesis.networking import with_args


class NetworkSerializer(object):
    "Serializes data to and from basic python types."
    def __init__(self, encoder=None, compress_level=6):
        self.encoder = encoder or json.JSONEncoder()
        self.compress_level = compress_level

    def serialize(self, obj):
        data = self.encoder.encode(obj)
        return zlib.compress(data, self.compress_level)

    def deserialize(self, data):
        data = zlib.decompress(data)
        return json.loads(data)


class BackendProtocol(object):
    version = 1
    def __init__(self, serializer=None):
        self.serializer = serializer or NetworkSerializer()

    def offer_handshake(self):
        "When the server accepts a client."
        return struct.pack('!I', self.version)

    def accept_handshake(self, stream, callback):
        "When the client connects to the server. Gives callback the metadata."
        def _consume_version(data):
            version = struct.unpack('!I', data)
            version = version[0] if version else -1
            metadata = {
                'version': version,
                'is_supported_version': version == self.version,
            }
            callback(metadata)
        # 4 bytes => 32-bit
        stream.read_bytes(4, _consume_version)


    def serialize(self, obj):
        data = self.serializer.serialize(obj)
        net_data = struct.pack('!%dc' % len(data), *list(data))
        return struct.pack('!Q', len(net_data)) + net_data

    def deserialize(self, stream, callback):
        def _consume_data(data, length):
            raw_data = ''.join(struct.unpack('!%dc' % length, data))
            callback(self.serializer.deserialize(raw_data))

        def _consume_length(data):
            length = struct.unpack('!Q', data)[0]
            stream.read_bytes(length, with_args(_consume_data, length))

        # 8 bytes => 64-bit
        stream.read_bytes(8, _consume_length)



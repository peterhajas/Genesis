"""Classes that handle the serialization of containers, usually to pass over
the wire.

All data is represented as strings.
"""
import zlib
import json

from genesis.networking import with_args


class NetworkSerializer(object):
    "Serializes data to and from basic python types."
    def __init__(self, encoder=None, compress_level=9):
        self.encoder = encoder or json.JSONEncoder()
        self.compress_level = compress_level

    def serialize(self, obj):
        data = self.encoder.encode(obj)
        if self.compress_level <= 0:
            return data
        return zlib.compress(data, self.compress_level)

    def deserialize(self, data):
        if self.compress_level > 0:
            data = zlib.decompress(data)
        return json.loads(data)


class BackendProtocol(object):
    def __init__(self, serializer=None):
        self.serializer = serializer or NetworkSerializer()

    def serialize(self, obj):
        data = self.serializer.serialize(obj)
        return str(len(data)) + ' ' + data

    def _consume_data(self, data, callback):
        callback(self.serializer.deserialize(data))

    def _consume_len(self, data, stream, callback):
        length = int(data)
        stream.read_bytes(length, with_args(self._consume_data, callback))

    def deserialize(self, stream, callback):
        stream.read_until(' ', with_args(self._consume_len, stream, callback))



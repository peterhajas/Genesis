"""Classes that handle the serialization of containers, usually to pass over
the wire.

All data is represented as strings.
"""
import zlib
import json
import struct

from genesis.utils import with_args


class NetworkSerializer(object):
    "Serializes data to and from basic python types."
    def __init__(self, encoder=None, compress_level=1):
        self.encoder = encoder or json.JSONEncoder()
        # never set higher than 1, doesn't really do much
        self.compress_level = compress_level

    def serialize_obj(self, obj):
        method = getattr(obj, 'to_network', None)
        if callable(method):
            return method()
        return obj

    def serialize(self, obj):
        data = self.encoder.encode(self.serialize_obj(obj))
        if self.compress_level:
            return zlib.compress(data, self.compress_level)
        return data

    def deserialize(self, data):
        if self.compress_level:
            data = zlib.decompress(data)
        return json.loads(data)


class ProtocolSerializer(object):
    """Handles the serializing and deserializing of the the network protocol.

    It uses serializer instance to handle the serialization & deserialization of
    the internal application format, independent from the simple message protocol.
    Optionally can provide a different serializer to NetworkSerializer.

    Delegate is a function that is invoked when the protocol encounters a
    format not defined in it specification. This can be either invalid handshake
    or a malformed message. The function should accept the iostream that caused the
    error. It is the responsibility of the delegate to close.

    If no delegate is provided, it simply closes the stream.
    """
    version = 2
    def __init__(self, serializer=None, delegate=None):
        self.serializer = serializer or NetworkSerializer()
        self.delegate = delegate

    def offer_handshake(self):
        "When the server accepts a client."
        return struct.pack('!h', self.version)

    def accept_handshake(self, stream, callback):
        "When the client connects to the server. Gives callback the metadata."
        def _consume_version(data):
            try:
                version = struct.unpack('!H', data)
            except struct.error:
                print "Malformed Handshake (version)"
                self._error_on_stream(stream)
                return

            version = version[0]
            metadata = {
                'version': version,
                'is_supported_version': version == self.version,
            }
            callback(metadata)
        # 4 bytes => 32-bit
        stream.read_bytes(2, _consume_version)


    def serialize(self, obj):
        "Serializes the given data to be sent over the network."
        data = self.serializer.serialize(obj)
        #net_data = struct.pack('!%dc' % len(data), *list(data))
        net_data = str(data)
        return struct.pack('!L', len(net_data)) + net_data

    def _error_on_stream(self, stream):
        if callable(self.delegate):
            self.delegate(stream)
        else:
            stream.close()

    def deserialize(self, stream, callback):
        def _consume_data(data, length):
            raw_data = str(data)
            #try:
            #    raw_data = ''.join(struct.unpack('!%dc' % length, data))
            #except struct.error:
            #    self._error_on_stream(stream)
            #    return

            callback(self.serializer.deserialize(raw_data))

        def _consume_length(data):
            try:
                length = struct.unpack('!L', data)[0]
            except struct.error:
                self._error_on_stream(stream)
                return

            stream.read_bytes(length, with_args(_consume_data, length))

        # 4 bytes => 8-bit
        stream.read_bytes(4, _consume_length)



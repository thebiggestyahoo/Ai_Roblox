"""Replace the cinematic script sources inside the supplied Roblox binary place."""
import argparse
import ctypes
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HEADER = struct.Struct("<4sIII")
MAPPING = {
    32: {"StoryCamera": "StoryCamera.client.luau"},
    37: {name: name + ".luau" for name in
         ("Config", "NarrationTiming", "StoryData", "PhotoArt", "ActorController", "WorldBuilder")},
    48: {"StoryWorld": "StoryWorld.server.luau"},
}

def chunks(data):
    offset = 32
    while offset < len(data):
        kind, compressed, length, reserved = HEADER.unpack_from(data, offset)
        end = offset + 16 + (compressed or length)
        if end > len(data):
            raise ValueError(f"Truncated {kind!r} chunk")
        payload = data[offset + 16:end]
        yield kind, compressed, length, reserved, payload
        offset = end

def decompress(payload, compressed, length):
    if not compressed:
        return payload
    target = ctypes.create_string_buffer(length)
    if payload.startswith(b"\x28\xb5\x2f\xfd"):
        library = ctypes.CDLL("libzstd.so.1")
        result = library.ZSTD_decompress(target, length, payload, len(payload))
    else:
        library = ctypes.CDLL("liblz4.so.1")
        result = library.LZ4_decompress_safe(payload, target, len(payload), length)
    if result != length:
        raise ValueError("Invalid compressed chunk")
    return target.raw

def pack_string(value):
    return struct.pack("<I", len(value)) + value

def strings(payload):
    while payload:
        length, = struct.unpack_from("<I", payload)
        value = payload[4:4+length]
        if len(value) != length:
            raise ValueError("Truncated string property")
        yield value
        payload = payload[4+length:]

def patch(source, output, uncompressed=False):
    data = source.read_bytes()
    if not data.startswith(b"<roblox!\x89\xff\r\n\x1a\n"):
        raise ValueError("Expected Roblox binary place")
    entries = list(chunks(data))
    names = {}
    for kind,c,n,_,p in entries:
        if kind != b"PROP":
            continue
        body = decompress(p,c,n)
        idx,length = struct.unpack_from("<II",body)
        if idx in MAPPING and body[8:8+length] == b"Name":
            assert body[8+length] == 1
            names[idx] = [value.decode() for value in strings(body[9+length:])]
    rewritten = set()
    output_data = bytearray(data[:32])
    for kind,c,n,reserved,p in entries:
        body = decompress(p,c,n) if kind == b"PROP" or uncompressed else b""
        new = None
        if kind == b"PROP":
            idx,length = struct.unpack_from("<II",body)
            if idx in MAPPING and body[8:8+length] == b"Source":
                assert body[8+length] == 1
                old = list(strings(body[9+length:]))
                assert len(old) == len(names[idx])
                for i,name in enumerate(names[idx]):
                    if name in MAPPING[idx]:
                        old[i] = (ROOT / "src" / MAPPING[idx][name]).read_bytes()
                        rewritten.add(name)
                new = body[:9+length] + b"".join(map(pack_string,old))
        if new is not None or uncompressed:
            payload = new if new is not None else body
            output_data += HEADER.pack(kind,0,len(payload),reserved) + payload
        else:
            output_data += HEADER.pack(kind,c,n,reserved) + p
    assert rewritten == {name for group in MAPPING.values() for name in group}, rewritten
    output.write_bytes(output_data)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--uncompressed", action="store_true")
    args = parser.parse_args()
    patch(args.source, args.output, args.uncompressed)

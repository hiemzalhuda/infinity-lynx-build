#!/usr/bin/env python3
"""Minimal update_engine payload (v1/v2) partition extractor.
Pure Python, no protobuf dependency. Parses DeltaArchiveManifest
with a tiny wire-format reader and reconstructs one partition
from its REPLACE operations.

Usage: payload_extract.py <payload.bin> <partition_name> <out.img>
"""
import struct
import sys


def read_varint(buf, pos):
    result = 0
    shift = 0
    while True:
        b = buf[pos]
        pos += 1
        result |= (b & 0x7F) << shift
        if not (b & 0x80):
            break
        shift += 7
    return result, pos


def parse_fields(buf):
    """Yield (field_number, wire_type, value); value is int or bytes."""
    pos = 0
    n = len(buf)
    while pos < n:
        tag, pos = read_varint(buf, pos)
        field = tag >> 3
        wt = tag & 7
        if wt == 0:
            v, pos = read_varint(buf, pos)
            yield field, wt, v
        elif wt == 1:
            v = buf[pos:pos + 8]
            pos += 8
            yield field, wt, v
        elif wt == 2:
            ln, pos = read_varint(buf, pos)
            v = buf[pos:pos + ln]
            pos += ln
            yield field, wt, v
        elif wt == 5:
            v = buf[pos:pos + 4]
            pos += 4
            yield field, wt, v
        else:
            raise ValueError("bad wire type %d at pos %d" % (wt, pos))


def get_string(msg, field_no):
    for f, wt, v in parse_fields(msg):
        if f == field_no and wt == 2:
            return v.decode("utf-8", "replace")
    return None


def main():
    path, want, out = sys.argv[1], sys.argv[2], sys.argv[3]
    with open(path, "rb") as f:
        header = f.read(20)
        assert header[:4] == b"CrAU", "bad magic: %r" % header[:4]
        version = struct.unpack(">Q", header[4:12])[0]
        manifest_size = struct.unpack(">Q", header[12:20])[0]
        # v2 layout: [20-byte header][4-byte metadata sig size][manifest]
        #            [metadata signature][data]. The sig-size field sits
        #            BEFORE the manifest (verified: data_start then matches
        #            the OTA metadata's payload_metadata.bin size exactly).
        sig_size = 0
        if version == 2:
            sig_size = struct.unpack(">I", f.read(4))[0]
        manifest = f.read(manifest_size)
        if version == 2:
            f.read(sig_size)
        data_start = f.tell()
        print("payload version=%d manifest_size=%d data_start=%d"
              % (version, manifest_size, data_start))
        block_size = 4096
        for fld, wt, v in parse_fields(manifest):
            if fld == 3 and wt == 0:
                block_size = v
        for fld, wt, v in parse_fields(manifest):
            # PartitionUpdate lives in field 13 in current manifests
            # (field 1 is the legacy slot); accept both.
            if fld in (1, 13) and wt == 2:
                name = get_string(v, 1)
                if name != want:
                    continue
                new_size = None
                ops = []
                for f2, wt2, v2 in parse_fields(v):
                    if f2 == 3 and wt2 == 2:
                        ops.append(v2)
                    if f2 == 8 and wt2 == 0:
                        new_size = v2
                buf = bytearray(new_size) if new_size else bytearray()
                for op in ops:
                    otype = None
                    doff = None
                    dlen = None
                    dsts = []
                    for f3, wt3, v3 in parse_fields(op):
                        if f3 == 1 and wt3 == 0:
                            otype = v3
                        elif f3 == 2 and wt3 == 0:
                            doff = v3
                        elif f3 == 3 and wt3 == 0:
                            dlen = v3
                        elif f3 == 6 and wt3 == 2:
                            sb = None
                            nb = None
                            for f4, wt4, v4 in parse_fields(v3):
                                if f4 == 1 and wt4 == 0:
                                    sb = v4
                                elif f4 == 2 and wt4 == 0:
                                    nb = v4
                            dsts.append((sb, nb))
                    if otype == 0 and doff is not None and dlen:
                        f.seek(data_start + doff)
                        data = f.read(dlen)
                        if len(data) != dlen:
                            raise IOError("short read: %d != %d" % (len(data), dlen))
                        off = 0
                        for (sb, nb) in dsts:
                            chunk = nb * block_size
                            pos = sb * block_size
                            if pos + chunk > len(buf):
                                buf.extend(b"\x00" * (pos + chunk - len(buf)))
                            buf[pos:pos + chunk] = data[off:off + chunk]
                            off += chunk
                    elif otype == 7:  # ZERO
                        for (sb, nb) in dsts:
                            pos = sb * block_size
                            chunk = nb * block_size
                            if pos + chunk > len(buf):
                                buf.extend(b"\x00" * (pos + chunk - len(buf)))
                    elif otype is not None and otype != 0:
                        print("WARN: unsupported op type %s for %s"
                              % (otype, want), file=sys.stderr)
                with open(out, "wb") as o:
                    o.write(bytes(buf))
                print("wrote %s (%d bytes), block_size=%d, ops=%d, new_size=%s"
                      % (out, len(buf), block_size, len(ops), new_size))
                return
        print("partition %s not found" % want, file=sys.stderr)
        sys.exit(1)


main()

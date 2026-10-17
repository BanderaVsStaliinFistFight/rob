"""Restore parts of the original file encoding that rbx_binary rewrites.

rbx_binary drops the META chunk (ExplicitAutoJoints) and migrates MeshPart.MeshId/TextureID
(string) to MeshContent/TextureContent (Content). Put the original chunks back so the arm
MeshParts are stored exactly as they were in the input file.
"""
import sys, struct, lz4.block, zstandard

HEADER = 32

def read_chunks(data):
    assert data[:8] == b'<roblox!'
    o, chunks = HEADER, []
    while o < len(data):
        name = data[o:o + 4]
        clen, ulen, _ = struct.unpack('<III', data[o + 4:o + 16])
        raw = data[o + 16:o + 16 + (clen or ulen)]
        if clen == 0:
            body = raw
        elif raw[:4] == b'\x28\xb5\x2f\xfd':
            body = zstandard.ZstdDecompressor().decompress(raw, max_output_size=ulen)
        else:
            body = lz4.block.decompress(raw, uncompressed_size=ulen)
        chunks.append([name, body, data[o:o + 16 + (clen or ulen)]])
        o += 16 + (clen or ulen)
        if name == b'END\0':
            break
    return chunks

def classes(chunks):
    out = {}
    for name, body, _ in chunks:
        if name == b'INST':
            cid, l = struct.unpack('<II', body[:8])
            n = struct.unpack('<I', body[9 + l:13 + l])[0]
            out[body[8:8 + l].decode()] = (cid, n)
    return out

def prop_key(body):
    cid, l = struct.unpack('<II', body[:8])
    return cid, body[8:8 + l].decode()

def raw_chunk(name, body):
    return name + struct.pack('<III', 0, len(body), 0) + body

src, out_in, out_path = sys.argv[1:4]
a_data, b_data = open(src, 'rb').read(), open(out_in, 'rb').read()
A, B = read_chunks(a_data), read_chunks(b_data)
ca, cb = classes(A), classes(B)
assert ca['MeshPart'][1] == cb['MeshPart'][1], 'MeshPart count changed'
a_mp, b_mp = ca['MeshPart'][0], cb['MeshPart'][0]

a_props = {prop_key(b)[1]: b for n, b, _ in A if n == b'PROP' and prop_key(b)[0] == a_mp}
swap = {'MeshContent': 'MeshId', 'TextureContent': 'TextureID'}
result = []
for name, body, raw in B:
    if name == b'PROP' and prop_key(body)[0] == b_mp and prop_key(body)[1] in swap:
        orig = bytearray(a_props[swap[prop_key(body)[1]]])
        orig[0:4] = struct.pack('<I', b_mp)  # class ids differ between the two files
        result.append(raw_chunk(b'PROP', bytes(orig)))
    else:
        result.append(raw)
meta = [raw for n, _, raw in A if n == b'META']
open(out_path, 'wb').write(b_data[:HEADER] + b''.join(meta) + b''.join(result))
print('wrote', out_path, 'meta chunks:', len(meta))

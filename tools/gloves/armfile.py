"""Shared helpers for reading the arm model (as .rbxmx XML) and its collision hull points."""
import base64, struct, xml.etree.ElementTree as ET
import numpy as np, zstandard


class ArmFile:
    def __init__(self, xml_path):
        self.root = ET.parse(xml_path).getroot()
        self.shared = {s.get('md5'): base64.b64decode(s.text or '')
                       for s in self.root.find('SharedStrings')}

    def arms(self):
        """Yields (model, meshpart, middle) for BodyRightArm / BodyLeftArm."""
        for model in self.root.iter('Item'):
            if model.get('class') == 'Model' and name_of(model).startswith('Body'):
                kids = model.findall('Item')
                mesh = next(k for k in kids if k.get('class') == 'MeshPart')
                middle = next(k for k in kids if name_of(k) == 'Middle')
                yield model, mesh, middle

    def hull_points(self, meshpart):
        """Collision hull vertices in mesh units (the mesh's InitialSize box)."""
        blob = self.shared[prop(meshpart, 'PhysicalConfigData').text.strip()]
        assert blob[:6] == b'CSGPHS'
        raw = zstandard.ZstdDecompressor().decompressobj().decompress(blob[12:])
        h = struct.unpack('<9I6f', raw[:60])
        start = 60 + h[7]
        pts = np.frombuffer(raw[start:start + h[8]], dtype='<f4').reshape(-1, 3).astype(float)
        assert len(pts) == h[1]
        return pts


def prop(it, name):
    return it.find('Properties').find(f"*[@name='{name}']")

def name_of(it):
    return prop(it, 'Name').text

def vec(e):
    return np.array([float(e.find(k).text) for k in 'XYZ'])

def mesh_scale(meshpart):
    return vec(prop(meshpart, 'size')) / vec(prop(meshpart, 'InitialSize'))


def prim_sdf(p, shape, size):
    """Signed distance to a Roblox part in its local frame (0 Ball, 1 Block, 2 Cylinder along X)."""
    h = np.asarray(size) / 2
    if shape == 0:
        return np.linalg.norm(p, axis=1) - h.min()
    if shape == 2:
        r = min(h[1], h[2])
        d = np.stack([np.abs(p[:, 0]) - h[0], np.linalg.norm(p[:, 1:], axis=1) - r], 1)
        return np.minimum(d.max(1), 0) + np.linalg.norm(np.maximum(d, 0), axis=1)
    q = np.abs(p) - h
    return np.linalg.norm(np.maximum(q, 0), axis=1) + np.minimum(q.max(1), 0)

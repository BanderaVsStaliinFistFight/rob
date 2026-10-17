"""Independent check of the written file: welds agree with CFrames, and the glove primitives cover the hand."""
import os, sys, base64, struct, xml.etree.ElementTree as ET
import numpy as np, zstandard
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cf import cf_from_xml, inv

root = ET.parse(sys.argv[1]).getroot()
items = {it.get('referent'): it for it in root.iter('Item')}
shared = {s.get('md5'): base64.b64decode(s.text or '') for s in root.find('SharedStrings')}
prop = lambda it, n: it.find('Properties').find(f"*[@name='{n}']")
name = lambda it: prop(it, 'Name').text
vec = lambda e: np.array([float(e.find(k).text) for k in 'XYZ'])

def prim_sdf(p, shape, size):
    h = size / 2
    if shape == 0:  # ball
        return np.linalg.norm(p, axis=1) - h.min()
    if shape == 2:  # cylinder along local X
        r = min(h[1], h[2])
        d = np.stack([np.abs(p[:, 0]) - h[0], np.linalg.norm(p[:, 1:], axis=1) - r], 1)
        return np.minimum(d.max(1), 0) + np.linalg.norm(np.maximum(d, 0), axis=1)
    q = np.abs(p) - h
    return np.linalg.norm(np.maximum(q, 0), axis=1) + np.minimum(q.max(1), 0)

ok = True
for model in [i for i in root.iter('Item') if i.get('class') == 'Model' and name(i).startswith('Body')]:
    kids = model.findall('Item')
    mesh = next(k for k in kids if k.get('class') == 'MeshPart')
    middle = next(k for k in kids if name(k) == 'Middle')
    gloves = [k for k in kids if name(k) in ('Glove', 'GloveCuff')]
    M_mesh = cf_from_xml(prop(mesh, 'CFrame')); M_mid = cf_from_xml(prop(middle, 'CFrame'))
    # 1) every glove part has exactly one weld from Middle that reproduces its CFrame
    welds = [w for w in middle.findall('Item') if w.get('class') == 'Weld']
    max_err = 0
    for g in gloves:
        ws = [w for w in welds if prop(w, 'Part1').text == g.get('referent')]
        assert len(ws) == 1 and prop(ws[0], 'Part0').text == middle.get('referent'), name(g)
        pred = M_mid @ cf_from_xml(prop(ws[0], 'C0')) @ inv(cf_from_xml(prop(ws[0], 'C1')))
        max_err = max(max_err, np.abs(pred - cf_from_xml(prop(g, 'CFrame'))).max())
        for flag, want in (('Anchored', 'false'), ('CanCollide', 'false'), ('Massless', 'true')):
            assert prop(g, flag).text == want, (name(g), flag)
        assert prop(g, 'Material').text == '2309' and prop(g, 'Transparency').text == '0'
    # 2) hand hull points (in mesh frame) are inside the glove primitives
    blob = shared[prop(mesh, 'PhysicalConfigData').text.strip()]
    raw = zstandard.ZstdDecompressor().decompressobj().decompress(blob[12:])
    h = struct.unpack('<9I6f', raw[:60])
    pm = np.frombuffer(raw[60 + h[7]:60 + h[7] + h[8]], '<f4').reshape(-1, 3).astype(float)
    scale = vec(prop(mesh, 'size')) / vec(prop(mesh, 'InitialSize'))
    pts = pm * scale
    sel = pts[:, 1] < -0.43   # everything under the glove + cuff, short of the cuff opening at y=-0.40
    P = np.c_[pts[sel], np.ones(sel.sum())]
    world = (M_mesh @ P.T).T
    depth = np.full(len(P), -np.inf)
    for g in gloves:
        local = (inv(cf_from_xml(prop(g, 'CFrame'))) @ world.T).T[:, :3]
        d = prim_sdf(local, int(prop(g, 'shape').text), vec(prop(g, 'size')))
        depth = np.maximum(depth, -d)
    worst = np.argsort(depth)[:3]
    print("   shallowest points (mesh frame):", pts[sel][worst].round(3).tolist(), depth[worst].round(4).tolist())
    covered = depth.min()
    print(f"{name(model)}: {len(gloves)} glove parts, weld/CFrame max err {max_err:.2e}, "
          f"{sel.sum()} hand points, min depth inside glove {covered:.3f} studs")
    ok &= max_err < 1e-3 and covered > 0.02
print('PASS' if ok else 'FAIL')
sys.exit(0 if ok else 1)

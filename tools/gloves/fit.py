"""Fit rounded-box gloves to each arm's hand, using the hull points from PhysicalConfigData.

Outputs a JSON spec of glove parts (shape, size, C0 relative to Middle, world CFrame).
All geometry is built in the arm MeshPart's local frame (scaled studs), then mapped to Middle space.
"""
import os, sys, json, base64, struct, xml.etree.ElementTree as ET
import numpy as np, zstandard
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cf import cf_from_xml, inv, T, rotY, rotZ

xml_path, out_path = sys.argv[1], sys.argv[2]
root = ET.parse(xml_path).getroot()
items = {it.get('referent'): it for it in root.iter('Item')}
shared = {s.get('md5'): base64.b64decode(s.text or '') for s in root.find('SharedStrings')}

def prop(it, name):
    return it.find('Properties').find(f"*[@name='{name}']")
def name_of(it):
    return prop(it, 'Name').text
def vec(e):
    return np.array([float(e.find(k).text) for k in 'XYZ'])

def hull_points(meshpart):
    blob = shared[prop(meshpart, 'PhysicalConfigData').text.strip()]
    assert blob[:6] == b'CSGPHS'
    raw = zstandard.ZstdDecompressor().decompressobj().decompress(blob[12:])
    h = struct.unpack('<9I6f', raw[:60])
    start = 60 + h[7]
    pts = np.frombuffer(raw[start:start + h[8]], dtype='<f4').reshape(-1, 3).astype(float)
    assert len(pts) == h[1]
    return pts

# ---- glove design parameters (studs) ----
T_BODY = 0.05     # glove shell clearance over the hand
R_BODY = 0.20     # edge rounding of the glove
CUFF_Y = (-0.64, -0.40)  # cuff band height range (mesh-local, scaled)
T_CUFF = 0.10     # cuff clearance over the forearm
CUFF_STEP = 0.035 # cuff sticks out at least this far past the glove shell
HAND_CUT = -0.52  # convex-decomposition cut plane between hand and forearm (mesh units)

def rounded_box_sdf(p, lo, hi, r, top):
    """Box [lo,hi] with all edges rounded by r except a flat top at y=top."""
    hi = hi.copy(); hi[1] += r  # push the top rounding above the clip plane
    c = (lo + hi) / 2; h = (hi - lo) / 2
    q = np.abs(p - c) - (h - r)
    d = np.linalg.norm(np.maximum(q, 0), axis=1) + np.minimum(q.max(axis=1), 0) - r
    return np.maximum(d, p[:, 1] - top)

def rounded_band_sdf(p, lo, hi, r):
    """Box [lo,hi] with only the vertical edges rounded by r (flat top and bottom)."""
    c = (lo + hi) / 2; h = (hi - lo) / 2
    q = np.abs(p[:, [0, 2]] - c[[0, 2]]) - (h[[0, 2]] - r)
    d2 = np.linalg.norm(np.maximum(q, 0), axis=1) + np.minimum(q.max(axis=1), 0) - r
    return d2  # callers only pass points inside the band's height range

def block(lo, hi):
    c = (lo + hi) / 2
    return dict(shape='Block', size=list(hi - lo), local=T(*c))

def cyl(center, length, radius, axis):
    rot = {'x': np.eye(4), 'y': rotZ(np.pi / 2), 'z': rotY(np.pi / 2)}[axis]
    return dict(shape='Cylinder', size=[length, 2 * radius, 2 * radius], local=T(*center) @ rot)

def ball(center, radius):
    return dict(shape='Ball', size=[2 * radius] * 3, local=T(*center))

def body_parts(lo, hi, r):
    """Rounded glove shell: rounded vertical + bottom edges, flat top (hidden under the cuff)."""
    (x0, y0, z0), (x1, y1, z1) = lo, hi
    xi0, xi1, zi0, zi1, yr = x0 + r, x1 - r, z0 + r, z1 - r, y0 + r
    parts = [
        block(np.array([x0, yr, zi0]), np.array([x1, y1, zi1])),
        block(np.array([xi0, yr, z0]), np.array([xi1, y1, z1])),
        block(np.array([xi0, y0, zi0]), np.array([xi1, y1, zi1])),
    ]
    for x in (xi0, xi1):
        for z in (zi0, zi1):
            parts.append(cyl([x, (yr + y1) / 2, z], y1 - yr, r, 'y'))
            parts.append(ball([x, yr, z], r))
    for z in (zi0, zi1):
        parts.append(cyl([(xi0 + xi1) / 2, yr, z], xi1 - xi0, r, 'x'))
    for x in (xi0, xi1):
        parts.append(cyl([x, yr, (zi0 + zi1) / 2], zi1 - zi0, r, 'z'))
    return parts

def band_parts(lo, hi, r):
    (x0, y0, z0), (x1, y1, z1) = lo, hi
    xi0, xi1, zi0, zi1 = x0 + r, x1 - r, z0 + r, z1 - r
    parts = [
        block(np.array([x0, y0, zi0]), np.array([x1, y1, zi1])),
        block(np.array([xi0, y0, z0]), np.array([xi1, y1, z1])),
    ]
    for x in (xi0, xi1):
        for z in (zi0, zi1):
            parts.append(cyl([x, (y0 + y1) / 2, z], y1 - y0, r, 'y'))
    return parts

def ensure_inside(sdf_fn, pts, lo, hi, clearance, what):
    """Grow the box until every point is at least `clearance` inside it."""
    for _ in range(200):
        d = sdf_fn(pts, lo, hi)
        worst = d.max()
        if worst <= -clearance:
            return lo, hi, d
        bad = pts[d > -clearance]
        c = (lo + hi) / 2
        for ax in (0, 2):
            if (bad[:, ax] > c[ax]).any(): hi[ax] += 0.002
            if (bad[:, ax] < c[ax]).any(): lo[ax] -= 0.002
        if what == 'body' and (bad[:, 1] < c[1]).any(): lo[1] -= 0.002
    raise RuntimeError(f'{what}: could not enclose points')

spec = []
report = []
for model in root.iter('Item'):
    if model.get('class') != 'Model' or not name_of(model).startswith('Body'):
        continue
    kids = model.findall('Item')
    mesh = next(k for k in kids if k.get('class') == 'MeshPart')
    middle = next(k for k in kids if name_of(k) == 'Middle')
    weld = next(w for w in middle.findall('Item')
                if w.get('class') == 'Weld' and prop(w, 'Part1').text == mesh.get('referent'))
    W = cf_from_xml(prop(weld, 'C0')) @ inv(cf_from_xml(prop(weld, 'C1')))  # Middle -> mesh
    middle_cf = cf_from_xml(prop(middle, 'CFrame'))

    scale = vec(prop(mesh, 'size')) / vec(prop(mesh, 'InitialSize'))
    pts_m = hull_points(mesh)
    pts = pts_m * scale

    hand = pts[pts_m[:, 1] <= HAND_CUT + 1e-4]
    lo = hand.min(0) - T_BODY
    hi = hand.max(0) + T_BODY
    hi[1] = HAND_CUT * scale[1] + 0.04  # top of shell tucks under the cuff
    lo, hi, d_body = ensure_inside(lambda p, a, b: rounded_box_sdf(p, a, b, R_BODY, b[1]),
                                   hand, lo, hi, 0.035, 'body')

    cy0, cy1 = CUFF_Y
    fore = pts[(pts[:, 1] >= cy0 - 0.05) & (pts[:, 1] <= cy1 + 0.05)]
    clo = np.minimum(fore.min(0) - T_CUFF, lo - CUFF_STEP)
    chi = np.maximum(fore.max(0) + T_CUFF, hi + CUFF_STEP)
    clo[1], chi[1] = cy0, cy1
    r_cuff = R_BODY + CUFF_STEP
    # the cuff has to cover the shell's top edge too, so test against shell surface samples
    shell_top = np.array([[x, y, z] for x in np.linspace(lo[0], hi[0], 25)
                          for z in np.linspace(lo[2], hi[2], 25)
                          for y in (cy0 + 0.01, hi[1])])
    shell_top = shell_top[rounded_box_sdf(shell_top, lo, hi, R_BODY, hi[1]) <= 1e-9]
    cuff_pts = np.vstack([fore[(fore[:, 1] >= cy0) & (fore[:, 1] <= cy1)], shell_top])
    clo, chi, d_cuff = ensure_inside(lambda p, a, b: rounded_band_sdf(p, a, b, r_cuff),
                                     cuff_pts, clo, chi, 0.01, 'cuff')

    # how snug is it? gap from glove surface to the nearest hand point along each face
    report.append(dict(arm=name_of(model), scale=scale.round(4).tolist(),
                       hand_min=hand.min(0).round(3).tolist(), hand_max=hand.max(0).round(3).tolist(),
                       body_lo=lo.round(3).tolist(), body_hi=hi.round(3).tolist(),
                       cuff_lo=clo.round(3).tolist(), cuff_hi=chi.round(3).tolist(),
                       body_min_clearance=round(-d_body.max(), 4),
                       cuff_min_clearance=round(-d_cuff.max(), 4),
                       body_parts=len(body_parts(lo, hi, R_BODY)), cuff_parts=len(band_parts(clo, chi, r_cuff))))

    for kind, parts in (('Glove', body_parts(lo, hi, R_BODY)), ('GloveCuff', band_parts(clo, chi, r_cuff))):
        for p in parts:
            c0 = W @ p['local']
            spec.append(dict(arm=name_of(model), name=kind, shape=p['shape'],
                             size=[round(float(s), 4) for s in p['size']],
                             c0=c0[:3, :].tolist(), world=(middle_cf @ c0)[:3, :].tolist(),
                             local=p['local'][:3, :].tolist()))

json.dump(dict(parts=spec, report=report), open(out_path, 'w'), indent=1)
for r in report:
    print(json.dumps(r))
print(len(spec), 'parts')

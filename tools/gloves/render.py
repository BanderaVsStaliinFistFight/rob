"""Preview render of the arms + gloves from the written file (arm shape rebuilt from its collision hull points)."""
import os, sys, base64, struct, xml.etree.ElementTree as ET
import numpy as np, zstandard
from scipy.spatial import ConvexHull
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cf import cf_from_xml, inv
from surface import cell_hulls

root = ET.parse(sys.argv[1]).getroot()
shared = {s.get('md5'): base64.b64decode(s.text or '') for s in root.find('SharedStrings')}
prop = lambda it, n: it.find('Properties').find(f"*[@name='{n}']")
name = lambda it: prop(it, 'Name').text
vec = lambda e: np.array([float(e.find(k).text) for k in 'XYZ'])
def rgb(it):
    v = int(prop(it, 'Color3uint8').text); return np.array([(v >> 16) & 255, (v >> 8) & 255, v & 255]) / 255

def box_tris(h):
    c = np.array([[sx, sy, sz] for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]) * h
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    return np.array([[c[a], c[b], c[d]] for a, b, cc, d in faces for (a, b, d) in ((a, b, cc), (a, cc, d))])
def cyl_tris(h, n=48):
    r = min(h[1], h[2]); t = np.linspace(0, 2 * np.pi, n + 1)
    ring = lambda x: np.stack([np.full(n + 1, x), r * np.cos(t), r * np.sin(t)], 1)
    a, b = ring(-h[0]), ring(h[0]); tris = []
    for i in range(n):
        tris += [[a[i], a[i + 1], b[i + 1]], [a[i], b[i + 1], b[i]],
                 [[-h[0], 0, 0], a[i + 1], a[i]], [[h[0], 0, 0], b[i], b[i + 1]]]
    return np.array(tris)
def ball_tris(h, nu=40, nv=20):
    r = h.min(); u = np.linspace(0, 2 * np.pi, nu + 1); v = np.linspace(0, np.pi, nv + 1)
    P = lambda i, j: r * np.array([np.sin(v[j]) * np.cos(u[i]), np.cos(v[j]), np.sin(v[j]) * np.sin(u[i])])
    return np.array([t for i in range(nu) for j in range(nv)
                     for t in ([P(i, j), P(i + 1, j), P(i + 1, j + 1)], [P(i, j), P(i + 1, j + 1), P(i, j + 1)])])

def xform(M, tris):
    p = tris.reshape(-1, 3); return (p @ M[:3, :3].T + M[:3, 3]).reshape(tris.shape)

meshes = []  # (tris_world, color)
mids = []
for model in [i for i in root.iter('Item') if i.get('class') == 'Model' and name(i).startswith('Body')]:
    kids = model.findall('Item')
    mesh = next(k for k in kids if k.get('class') == 'MeshPart')
    mids.append(cf_from_xml(prop(next(k for k in kids if name(k) == 'Middle'), 'CFrame')))
    blob = shared[prop(mesh, 'PhysicalConfigData').text.strip()]
    raw = zstandard.ZstdDecompressor().decompressobj().decompress(blob[12:])
    hd = struct.unpack('<9I6f', raw[:60])
    pm = np.frombuffer(raw[60 + hd[7]:60 + hd[7] + hd[8]], '<f4').reshape(-1, 3).astype(float)
    # the same rebuilt arm surface the glove was fitted to
    tris = []
    for _, verts in cell_hulls(pm, vec(prop(mesh, 'size')) / vec(prop(mesh, 'InitialSize'))):
        tris.append(verts[ConvexHull(verts).simplices])
    meshes.append((xform(cf_from_xml(prop(mesh, 'CFrame')), np.concatenate(tris)), rgb(mesh)))
    for g in kids:
        if not name(g).startswith('Glove'): continue
        h = vec(prop(g, 'size')) / 2; shape = int(prop(g, 'shape').text)
        t = {0: ball_tris, 1: box_tris, 2: cyl_tris}[shape](h)
        meshes.append((xform(cf_from_xml(prop(g, 'CFrame')), t), rgb(g)))

# character frame: Middle's axes (Roblox: -Z is forward), centred between the arms
F = mids[0].copy(); F[:3, 3] = (mids[0][:3, 3] + mids[1][:3, 3]) / 2
toChar = inv(F)
meshes = [(xform(toChar, t), c) for t, c in meshes]

def render(yaw, pitch, center, scale, W, H):
    cy, sy, cp, sp = np.cos(yaw), np.sin(yaw), np.cos(pitch), np.sin(pitch)
    # camera sits in front of the character (-Z), rotated by yaw around Y and pitched down
    fwd = np.array([-sy * cp, -sp, cy * cp])          # camera looks along +fwd
    right = np.cross(np.array([0, 1, 0]), fwd); right /= np.linalg.norm(right)
    right = -right
    up = np.cross(fwd, right) * -1
    light = -0.6 * fwd + 0.65 * up - 0.4 * right; light /= np.linalg.norm(light)  # toward the light
    img = np.ones((H, W, 3)) * np.array([0.80, 0.83, 0.87])
    yy = np.linspace(0, 1, H)[:, None, None]
    img = img * (1 - 0.18 * yy)
    zb = np.full((H, W), np.inf)
    for tris, col in meshes:
        p = tris - center
        sx = (p @ right) * scale + W / 2; sy_ = -(p @ up) * scale + H / 2; dz = p @ fwd
        n = np.cross(tris[:, 1] - tris[:, 0], tris[:, 2] - tris[:, 0])
        nl = np.linalg.norm(n, axis=1); good = nl > 1e-12
        n[good] /= nl[good][:, None]
        n[(n @ fwd) > 0] *= -1                      # face the camera
        diff = np.clip(n @ light, 0, 1)
        half = light - fwd; half /= np.linalg.norm(half)
        spec = np.clip(n @ half, 0, 1) ** 40
        shade = col * (0.32 + 0.68 * diff[:, None]) + 0.28 * spec[:, None]
        for i in np.nonzero(good)[0]:
            x, y, z = sx[i], sy_[i], dz[i]
            x0, x1 = int(max(np.floor(x.min()), 0)), int(min(np.ceil(x.max()), W - 1))
            y0, y1 = int(max(np.floor(y.min()), 0)), int(min(np.ceil(y.max()), H - 1))
            if x0 > x1 or y0 > y1: continue
            X, Y = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
            d = (y[1] - y[2]) * (x[0] - x[2]) + (x[2] - x[1]) * (y[0] - y[2])
            if abs(d) < 1e-12: continue
            a = ((y[1] - y[2]) * (X - x[2]) + (x[2] - x[1]) * (Y - y[2])) / d
            b = ((y[2] - y[0]) * (X - x[2]) + (x[0] - x[2]) * (Y - y[2])) / d
            c = 1 - a - b
            inside = (a >= -1e-6) & (b >= -1e-6) & (c >= -1e-6)
            Z = a * z[0] + b * z[1] + c * z[2]
            sub = zb[y0:y1 + 1, x0:x1 + 1]
            m = inside & (Z < sub)
            sub[m] = Z[m]
            img[y0:y1 + 1, x0:x1 + 1][m] = shade[i]
    return Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8))

W, H = 520, 620
views = [
    ('Front', render(np.radians(15), np.radians(10), np.array([0, -0.05, 0]), 100, W, H)),
    ('Back', render(np.radians(180 + 20), np.radians(10), np.array([0, -0.05, 0]), 100, W, H)),
    ('Right arm, outer side', render(np.radians(70), np.radians(12), np.array([1.5, -0.1, 0]), 200, W, H)),
]
pad = 12; sheet = Image.new('RGB', (len(views) * (W + pad) + pad, H + 2 * pad + 26), (245, 246, 248))
dr = ImageDraw.Draw(sheet)
for i, (label, im) in enumerate(views):
    x = pad + i * (W + pad); sheet.paste(im, (x, pad + 26)); dr.text((x + 4, pad + 6), label, fill=(40, 40, 46))
sheet.save(sys.argv[2])
print('saved', sys.argv[2], sheet.size)

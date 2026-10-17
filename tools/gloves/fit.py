"""Fit thin, elbow-length gloves to each arm, using the hull points stored in PhysicalConfigData.

The glove follows the arm's measured cross-section along its whole length. Each ring of the
glove is an octagon (four sides plus four corner faces) whose vertices are rounded with one
fixed radius, so the shape can hug the arm's corners while every piece flows straight into the
next one. The glove is built from:
  - a rounded cap over the hand (flat underside, filleted edges and corners),
  - tube segments: eight tilted panels plus eight corner cylinders each, with a ball wherever
    a corner bends at a joint,
  - a slightly raised, straight hem at the opening.
Geometry is built in the arm MeshPart's local frame (scaled studs; the arm spans
y = -1.125..1.125) and written as a JSON spec for `rbxtool gloves`.

usage: fit.py <arms.rbxmx> <spec.json>
"""
import os, sys, json
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from armfile import ArmFile, prop, name_of, mesh_scale
from cf import cf_from_xml, inv, T
from surface import cell_hulls, slice_outline, underside
from check import union_sdf, report

# ---- glove design (studs) ----
THICK = 0.02        # glove surface sits this far off the arm at each ring
MIN_CLEAR = 0.012   # and never closer than this anywhere in between
TOP = 0.55          # glove opening, halfway up the upper arm (opera length)
SEG = 0.29          # target length of each tube segment
HEM_HEIGHT = 0.08   # straight band around the opening; it also covers the tube's last joint
HEM_THICK = 0.03    # the hem stands slightly proud of the glove
FILLET = 0.12       # rounding of the tube's eight edges (the hand cap picks its own, rounder)
PANEL_DEPTH = 0.15  # panels extend this far inward, hidden inside the arm
OVERLAP = 0.004     # neighbouring panels overlap this much so the joints have no cracks
ELBOW_BEND = 3.0    # fillets that bend more than this (degrees) at a joint get a ball there
COLOR = [255, 102, 204]  # Roblox "Pink"
MATERIAL = 272           # SmoothPlastic

Y = np.array([0.0, 1.0, 0.0])


class Octagon:
    """Glove cross-section: eight faces at 45 degree steps (four sides and four corner faces),
    vertices rounded with radius r. A ring is then just the eight face offsets h from the arm
    axis."""

    def __init__(self, r):
        phi = np.radians(np.arange(8) * 45.0)
        self.phi, self.r = phi, r
        self.U = np.stack([np.cos(phi), np.sin(phi)], 1)      # outward normals in (x, z)
        self.TAN = np.stack([-np.sin(phi), np.cos(phi)], 1)   # along each face, counter-clockwise

    def _meet(self, a, b, h):
        return np.linalg.solve(np.stack([self.U[a], self.U[b]]), [h[a] - self.r, h[b] - self.r])

    def clip(self, h):
        """A corner face can't sit outside the point where its two neighbours meet."""
        h = h.copy()
        for m in (1, 3, 5, 7):
            h[m] = min(h[m], self._meet(m - 1, (m + 1) % 8, h) @ self.U[m] + self.r)
        return h

    def vertices(self, h):
        """Inner vertex m joins face m and face m+1 (the fillet centres)."""
        return np.array([self._meet(m, (m + 1) % 8, h) for m in range(8)])

    def sdf(self, P, h):
        V = self.vertices(h)
        inside = (P @ self.U.T - (h - self.r)).max(1)
        dist = np.full(len(P), np.inf)
        for m in range(8):
            a, ab = V[m - 1], V[m] - V[m - 1]
            t = np.clip(((P - a) @ ab) / max(ab @ ab, 1e-12), 0, 1)
            dist = np.minimum(dist, np.linalg.norm(P - (a + t[:, None] * ab), axis=1))
        return np.where(inside <= 0, inside, dist) - self.r

    def support(self, P):
        return (P @ self.U.T).max(0)

    def fit(self, outline, clear):
        return self.push_out(self.clip(self.support(outline) + THICK), outline, clear)

    def push_out(self, h, outline, clear, iters=40):
        """Grow the faces next to any outline point that comes closer than `clear`."""
        for _ in range(iters):
            h = self.clip(h)
            d = self.sdf(outline, h) + clear
            if d.max() <= 1e-7:
                break
            bad = d > 1e-7
            ang = np.arctan2(outline[bad, 1], outline[bad, 0]) % (2 * np.pi)
            m1 = np.searchsorted(self.phi, ang, side='right') - 1
            for m, dd in zip(np.r_[m1, (m1 + 1) % 8], np.r_[d[bad], d[bad]]):
                h[m] += dd
        return self.clip(h)

def lerp(a, b, t):
    return (1 - t) * a + t * b

# ---- parts ----
def block(center, cols, size):
    M = T(*center); M[:3, :3] = np.stack(cols, 1)
    return dict(shape='Block', size=list(size), local=M)

def cylinder(a, b, radius, ext_a=0.0, ext_b=0.0):
    axis = b - a; length = np.linalg.norm(axis); X = axis / length
    helper = [1.0, 0, 0] if abs(X[2]) > 0.9 else [0.0, 0, 1]
    Yc = np.cross(helper, X); Yc /= np.linalg.norm(Yc); Zc = np.cross(X, Yc)
    center = (a + b) / 2 + X * (ext_b - ext_a) / 2
    M = T(*center); M[:3, :3] = np.stack([X, Yc, Zc], 1)
    return dict(shape='Cylinder', size=[length + ext_a + ext_b, 2 * radius, 2 * radius], local=M)

def ball(center, radius):
    return dict(shape='Ball', size=[2 * radius] * 3, local=T(*center))

def to3(v2, y):
    return np.array([v2[0], y, v2[1]])

def segment_parts(o, ya, ha, yb, hb, ext_a, ext_b, cyl_ext_a, cyl_ext_b):
    """Eight tilted panels + eight fillet cylinders between two rings of octagon o.
    ext_*: how far the panels run past each ring; cyl_ext_*: the same per fillet cylinder."""
    parts = []
    Va, Vb = o.vertices(ha), o.vertices(hb)
    for m in range(8):
        e, along = to3(o.U[m], 0), to3(o.TAN[m], 0)
        dh, dy = hb[m] - ha[m], yb - ya
        L = np.hypot(dh, dy)
        u = (e * dh + Y * dy) / L                # up the arm, on the panel's outer face
        n = (e * dy - Y * dh) / L                # outward normal
        lo = (Va[m - 1] + Vb[m - 1]) @ o.TAN[m] / 2
        hi = (Va[m] + Vb[m]) @ o.TAN[m] / 2
        if hi - lo < 0.01:
            continue                             # corner face too narrow to need a panel
        center = (e * (ha[m] + hb[m]) / 2 + Y * (ya + yb) / 2 + along * (lo + hi) / 2
                  - n * PANEL_DEPTH / 2 + u * (ext_b - ext_a) / 2)
        parts.append(block(center, [n, u, np.cross(n, u)], [PANEL_DEPTH, L + ext_a + ext_b, hi - lo]))
    for m in range(8):
        if m % 2 == 0 and np.linalg.norm(Va[m] - Va[m + 1]) < 1e-6 and np.linalg.norm(Vb[m] - Vb[m + 1]) < 1e-6:
            continue                             # same fillet as the next one (no corner face)
        parts.append(cylinder(to3(Va[m], ya), to3(Vb[m], yb), o.r, cyl_ext_a[m], cyl_ext_b[m]))
    return parts

def cap_parts(y_bottom, s, r):
    """Rounded bottom over the hand: flat underside, filleted edges and corners of radius r.
    s = [+x, -x, +z, -z] side offsets."""
    y0 = y_bottom + r
    x0, x1, z0, z1 = -(s[1] - r), s[0] - r, -(s[3] - r), s[2] - r
    parts = [block([(x0 + x1) / 2, (y_bottom + y0 + OVERLAP) / 2, (z0 + z1) / 2], list(np.eye(3)),
                   [x1 - x0, y0 + OVERLAP - y_bottom, z1 - z0])]
    for z in (z0, z1):
        parts.append(cylinder(np.array([x0, y0, z]), np.array([x1, y0, z]), r, 0, 0))
    for x in (x0, x1):
        parts.append(cylinder(np.array([x, y0, z0]), np.array([x, y0, z1]), r, 0, 0))
    for x in (x0, x1):
        for z in (z0, z1):
            parts.append(ball([x, y0, z], r))
    return parts

def cap_ring(o, s, r_cap):
    """The cap's top outline (a rounded rectangle, corner radius r_cap) as an octagon whose
    corner faces touch the cap's rounded corners."""
    h = np.array([s[0], 0, s[2], 0, s[1], 0, s[3], 0], float)
    for m in (1, 3, 5, 7):
        centre = np.linalg.solve(np.stack([o.U[m - 1], o.U[(m + 1) % 8]]),
                                 [h[m - 1] - r_cap, h[(m + 1) % 8] - r_cap])
        h[m] = centre @ o.U[m] + r_cap
    return o.clip(h)

def fit_arm(pm, scale):
    hulls = cell_hulls(pm, scale)
    pts = pm * scale
    y_bottom = pts[:, 1].min() - THICK
    cache = {}
    def ol(y):
        key = round(y, 4)
        if key not in cache:
            cache[key] = slice_outline(hulls, y)
        return cache[key]
    def ext(P):
        return np.array([P[:, 0].max(), -P[:, 0].min(), P[:, 1].max(), -P[:, 1].min()])

    # -- rounded cap over the hand: the roundest fillet that still clears the hand --
    grid = np.array([(x, z) for x in np.arange(-0.8, 0.8, 0.02) for z in np.arange(-0.8, 0.8, 0.02)])
    under = underside(hulls, grid)
    hand_bottom = np.c_[grid[:, 0], under, grid[:, 1]][np.isfinite(under)]
    for r in np.arange(0.30, 0.08, -0.01):
        y0 = y_bottom + r
        ys = np.arange(y_bottom + THICK + 0.005, y0 + 0.02, 0.01)
        s_cap = np.max([ext(ol(y)) for y in ys], 0) + THICK
        test = np.vstack([hand_bottom[hand_bottom[:, 1] < y0],
                          *[np.c_[ol(y)[:, 0], np.full(len(ol(y)), y), ol(y)[:, 1]] for y in ys]])
        if union_sdf(cap_parts(y_bottom, s_cap, r), test).max() <= -MIN_CLEAR:
            break
    y0 = y_bottom + r

    # -- tube rings from the top of the cap to halfway up the hem --
    tube_top = TOP - HEM_HEIGHT / 2
    n_seg = int(np.ceil((tube_top - y0) / SEG))
    ring_y = np.linspace(y0, tube_top, n_seg + 1)
    o = Octagon(FILLET)
    rings = [cap_ring(o, s_cap, r)] + [o.fit(ol(y), THICK * 0.75) for y in ring_y[1:]]
    # push rings out wherever the arm bulges between them (the cap's ring stays put)
    seg_ys = [np.arange(ring_y[i], ring_y[i + 1] + 1e-9, 0.01) for i in range(n_seg)]
    for _ in range(12):
        grew = False
        for i in range(n_seg):
            for y in seg_ys[i]:
                t = (y - ring_y[i]) / (ring_y[i + 1] - ring_y[i])
                h = lerp(rings[i], rings[i + 1], t)
                need = o.push_out(h, ol(y), MIN_CLEAR) - h
                if need.max() > 1e-6:
                    if i == 0:
                        rings[1] = o.clip(rings[1] + need / max(t, 0.25))
                    else:
                        rings[i] = o.clip(rings[i] + need)
                        rings[i + 1] = o.clip(rings[i + 1] + need)
                    grew = True
        if not grew:
            break

    # Where a fillet cylinder changes direction at a joint, its flat end leaves a wedge open on
    # the outside of the bend. Small bends: run both cylinders past the joint by r * tan(bend).
    # Bigger ones get a ball at the joint instead, like a pipe elbow. The hem covers the last
    # joint, and the first one also counts the cap's straight-up edges as the incoming direction.
    axes = []
    for i in range(n_seg):
        d = o.vertices(rings[i + 1]) - o.vertices(rings[i])
        a3 = np.c_[d[:, 0], np.full(8, ring_y[i + 1] - ring_y[i]), d[:, 1]]
        axes.append(a3 / np.linalg.norm(a3, axis=1)[:, None])
    tilt = np.degrees(np.arccos(np.abs(axes[-1][:, 1])))
    assert (o.r * np.tan(np.radians(tilt)) < HEM_HEIGHT / 2).all(), 'top joint would show past the hem'
    up = np.tile([0.0, 1.0, 0.0], (8, 1))
    incoming = [up] + axes[:-1]
    glove = cap_parts(y_bottom, s_cap, r)
    joint_ext = []
    for i in range(n_seg):
        bend = np.arccos(np.clip((incoming[i] * axes[i]).sum(1), -1, 1))
        elbow = np.degrees(bend) > ELBOW_BEND
        V = o.vertices(rings[i])
        glove += [ball(to3(V[m], ring_y[i]), o.r) for m in np.nonzero(elbow)[0]]
        joint_ext.append(np.where(elbow, 0.0, o.r * np.tan(bend) + OVERLAP))
    joint_ext.append(np.zeros(8))
    for i in range(n_seg):
        glove += segment_parts(o, ring_y[i], rings[i], ring_y[i + 1], rings[i + 1], OVERLAP, OVERLAP,
                               joint_ext[i], joint_ext[i + 1])

    # hem: a straight band a little proud of the tube, so the opening has a clean flat edge
    hem_ys = np.arange(TOP - HEM_HEIGHT, TOP + 1e-9, 0.01)
    t0 = (TOP - HEM_HEIGHT - ring_y[-2]) / (ring_y[-1] - ring_y[-2])
    h_hem = np.maximum(lerp(rings[-2], rings[-1], t0), rings[-1])
    near_top = pts[(pts[:, 1] > TOP - HEM_HEIGHT - 0.01) & (pts[:, 1] < TOP + 0.01)][:, [0, 2]]
    for y in hem_ys:
        h_hem = o.push_out(h_hem, np.vstack([ol(y), near_top]), THICK)
    h_hem = o.clip(h_hem + (HEM_THICK - THICK))
    hem = segment_parts(o, TOP - HEM_HEIGHT, h_hem, TOP, h_hem, 0, 0, np.zeros(8), np.zeros(8))

    # -- how well does it fit? --
    bends = [np.degrees(np.arccos(np.clip((axes[i - 1] * axes[i]).sum(1), -1, 1))) for i in range(1, n_seg)]
    stats = dict(cap_radius=round(float(r), 3), segments=n_seg,
                 max_fillet_tilt=round(float(max(np.degrees(np.arccos(np.abs(a[:, 1]))).max() for a in axes)), 1),
                 max_fillet_bend=round(float(max(b.max() for b in bends)), 1),
                 **report(glove + hem, hulls, y_bottom + THICK + 0.005, TOP))
    return glove, hem, stats


def main():
    arms = ArmFile(sys.argv[1])
    spec, summary = [], []
    for model, mesh, middle in arms.arms():
        weld = next(w for w in middle.findall('Item')
                    if w.get('class') == 'Weld' and prop(w, 'Part1').text == mesh.get('referent'))
        W = cf_from_xml(prop(weld, 'C0')) @ inv(cf_from_xml(prop(weld, 'C1')))  # Middle -> mesh
        middle_cf = cf_from_xml(prop(middle, 'CFrame'))
        glove, hem, stats = fit_arm(arms.hull_points(mesh), mesh_scale(mesh))
        summary.append(dict(arm=name_of(model), parts=len(glove) + len(hem), **stats))
        for kind, parts in (('Glove', glove), ('GloveHem', hem)):
            for p in parts:
                c0 = W @ p['local']
                spec.append(dict(arm=name_of(model), name=kind, shape=p['shape'],
                                 size=[round(float(v), 4) for v in p['size']],
                                 color=COLOR, material=MATERIAL,
                                 c0=c0[:3, :].tolist(), world=(middle_cf @ c0)[:3, :].tolist()))
    json.dump(dict(parts=spec, report=summary), open(sys.argv[2], 'w'), indent=1)
    for r in summary:
        print(json.dumps(r))
    print(len(spec), 'parts')

if __name__ == '__main__':
    main()

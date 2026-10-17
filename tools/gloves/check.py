"""Measure how a set of glove parts sits on the arm, using the glove's real outer surface.

The glove is traced from outside (rays coming in toward the arm, and up from under the hand),
so the hidden inner faces of the thin panels never count. Every arm surface sample is then
compared with that outer skin.
"""
import numpy as np
from scipy.ndimage import uniform_filter1d
from scipy.spatial import cKDTree
from cf import inv
from armfile import prim_sdf
from surface import radius, underside, THETAS

SHAPES = {'Ball': 0, 'Block': 1, 'Cylinder': 2}

def union_sdf(parts, pts):
    d = np.full(len(pts), np.inf)
    P = np.c_[pts, np.ones(len(pts))]
    for p in parts:
        local = (inv(p['local']) @ P.T).T[:, :3]
        d = np.minimum(d, prim_sdf(local, SHAPES[p['shape']], p['size']))
    return d

def trace(parts, origins, dirs, max_dist, iters=80):
    """Sphere-trace each ray to the first glove surface; NaN where it never hits."""
    t = np.zeros(len(origins))
    for _ in range(iters):
        s = union_sdf(parts, origins + dirs * t[:, None])
        t = t + np.maximum(s, 0)
        if (s < 1e-5).all() or (t > max_dist).all():
            break
    return np.where((s < 1e-4) & (t < max_dist), t, np.nan)

def glove_radius(parts, ys, start=1.3):
    """Outer glove radius along each (height, THETAS) ray, coming in from `start`."""
    Y, TH = np.meshgrid(ys, THETAS, indexing='ij')
    d = np.c_[-np.cos(TH.ravel()), np.zeros(TH.size), -np.sin(TH.ravel())]
    o = np.c_[start * np.cos(TH.ravel()), Y.ravel(), start * np.sin(TH.ravel())]
    return (start - trace(parts, o, d, start)).reshape(Y.shape)

def glove_underside(parts, xz, below=-2.0):
    o = np.c_[xz[:, 0], np.full(len(xz), below), xz[:, 1]]
    d = np.tile([0.0, 1.0, 0.0], (len(xz), 1))
    return below + trace(parts, o, d, 3.0)

def report(parts, hulls, y_from, top):
    """Fit numbers for a glove covering the arm from its underside up to height `top`."""
    ys = np.arange(y_from, top - 0.02, 0.01)
    G = glove_radius(parts, ys)
    A = np.array([radius(hulls, y, THETAS) for y in ys])
    A[A < 0.05] = np.nan
    radial = G - A                                     # side clearance along each ray
    xs = np.arange(-0.8, 0.8, 0.02)
    xz = np.array([(x, z) for x in xs for z in xs])
    ya, yg = underside(hulls, xz), glove_underside(parts, xz)
    low = ya < y_from + 0.15
    vertical = (ya - yg)[low]                          # clearance under the hand

    # true (normal) clearance: distance from arm surface samples to the glove's outer skin
    Y, TH = np.meshgrid(ys, THETAS, indexing='ij')
    skin = np.c_[(G * np.cos(TH)).ravel(), Y.ravel(), (G * np.sin(TH)).ravel()]
    skin = np.vstack([skin[np.isfinite(skin).all(1)],
                      np.c_[xz[:, 0], yg, xz[:, 1]][np.isfinite(yg)]])
    arm = np.vstack([np.c_[(A * np.cos(TH)).ravel(), Y.ravel(), (A * np.sin(TH)).ravel()],
                     np.c_[xz[low, 0], ya[low], xz[low, 1]]])
    arm = arm[np.isfinite(arm).all(1)]
    normal = cKDTree(skin).query(arm)[0]

    # nothing may stick out above the opening
    above = np.arange(top + 0.005, top + 0.3, 0.01)
    Ga = glove_radius(parts, above)
    Aa = np.array([radius(hulls, y, THETAS) for y in above])
    poke = np.nanmax(np.where(np.isfinite(Ga), Ga - Aa, -1.0))

    # bumps: how far the outer surface strays from a smooth curve along the arm
    bumps = np.abs(G - uniform_filter1d(G, 9, axis=0))[5:-5]
    return dict(
        covered=bool(np.nanmin(radial) > 0 and np.nanmin(vertical) > 0),
        min_side_gap=round(float(np.nanmin(radial)), 4),
        min_underside_gap=round(float(np.nanmin(vertical)), 4),
        min_clearance=round(float(normal.min()), 4),
        median_gap=round(float(np.nanmedian(radial)), 4),
        p95_gap=round(float(np.nanpercentile(radial, 95)), 4),
        sticks_out_above_opening=round(float(max(poke, 0.0)), 4),
        bump_p99=round(float(np.nanpercentile(bumps, 99)), 4),
    )

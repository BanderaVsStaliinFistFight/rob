"""Rebuild an arm's outer surface from its collision hull points and ray-cast it.

The convex decomposition is cut at y = -0.523, 0, +0.523 and roughly at x = 0 and z = 0
(mesh units), so the points are grouped into those 16 cells and each cell's convex hull is
used. Merging the finer hulls inside a cell can only bridge over dents, never cut into the arm.
"""
import numpy as np
from scipy.spatial import ConvexHull

Y_CUTS = (-0.523, 0.0, 0.523)

def cell_hulls(pm, scale):
    """pm: hull points in mesh units. Returns hull equations (a.x + b <= 0 inside) in scaled studs."""
    pts = pm * scale
    ys = np.array([-np.inf, *Y_CUTS, np.inf])
    hulls = []
    for k in range(4):
        for sx in (-1, 1):
            for sz in (-1, 1):
                m = ((pm[:, 1] >= ys[k] - 2e-3) & (pm[:, 1] <= ys[k + 1] + 2e-3)
                     & (pm[:, 0] * sx >= -0.02) & (pm[:, 2] * sz >= -0.02))
                if m.sum() >= 4:
                    h = ConvexHull(pts[m])
                    hulls.append((h.equations, pts[m][h.vertices]))
    return hulls

def cast(hulls, origins, dirs):
    """Rays against the cell hulls: (nearest entry, farthest exit) distance, NaN where missed."""
    enter = np.full(len(dirs), np.inf)
    exit_ = np.full(len(dirs), -np.inf)
    for eq, _ in hulls:
        n, b = eq[:, :3], eq[:, 3]
        side = origins @ n.T + b                # (rays, faces); > 0: origin outside that face
        nd = dirs @ n.T
        with np.errstate(divide='ignore', invalid='ignore'):
            t = -side / nd
        t_exit = np.where(nd > 1e-12, t, np.inf).min(1)
        t_enter = np.where(nd < -1e-12, t, -np.inf).max(1)
        parallel_miss = ((np.abs(nd) <= 1e-12) & (side > 0)).any(1)
        hit = (t_enter <= t_exit) & (t_exit > 0) & ~parallel_miss
        enter = np.where(hit, np.minimum(enter, np.maximum(t_enter, 0)), enter)
        exit_ = np.where(hit, np.maximum(exit_, t_exit), exit_)
    miss = ~np.isfinite(exit_)
    enter[miss] = np.nan; exit_[miss] = np.nan
    return enter, exit_

def radius(hulls, y, thetas, center=(0.0, 0.0)):
    """Distance from (cx, y, cz) to the arm surface along each horizontal direction theta."""
    d = np.stack([np.cos(thetas), np.zeros_like(thetas), np.sin(thetas)], 1)
    o = np.tile([center[0], y, center[1]], (len(thetas), 1))
    r = cast(hulls, o, d)[1]
    return np.nan_to_num(r, nan=0.0)

def underside(hulls, xz, below=-2.0):
    """Height of the arm's underside above each (x, z), NaN where there's no arm."""
    o = np.c_[xz[:, 0], np.full(len(xz), below), xz[:, 1]]
    d = np.tile([0.0, 1.0, 0.0], (len(xz), 1))
    return below + cast(hulls, o, d)[0]


THETAS = np.radians(np.arange(0.5, 360, 1.0))  # off-axis, so rays never run along a cut plane

def slice_outline(hulls, y):
    """Arm outline at height y as (N, 2) points (x, z); rays that miss are dropped."""
    r = radius(hulls, y, THETAS)
    keep = r > 0.05
    return np.stack([r * np.cos(THETAS), r * np.sin(THETAS)], 1)[keep]

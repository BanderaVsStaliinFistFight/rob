"""Independent check of the written file.

For each arm: every glove part has one weld from Middle that reproduces its CFrame, the parts
have the right physics flags, and, measured against the glove's real outer surface, the arm is
covered everywhere up to the opening and nothing sticks out above it.

usage: verify.py <arms-with-gloves.rbxmx>
"""
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from armfile import ArmFile, prop, name_of, vec, mesh_scale
from cf import cf_from_xml, inv
from surface import cell_hulls
from check import report
import fit

SHAPE_NAMES = {0: 'Ball', 1: 'Block', 2: 'Cylinder'}
MIN_CLEARANCE = 0.008  # studs between the arm surface and the glove's outer surface

arms = ArmFile(sys.argv[1])
ok = True
for model, mesh, middle in arms.arms():
    gloves = [k for k in model.findall('Item') if name_of(k).startswith('Glove')]
    M_mesh, M_mid = cf_from_xml(prop(mesh, 'CFrame')), cf_from_xml(prop(middle, 'CFrame'))
    welds = [w for w in middle.findall('Item') if w.get('class') == 'Weld']
    max_err, parts = 0.0, []
    for g in gloves:
        ws = [w for w in welds if prop(w, 'Part1').text == g.get('referent')]
        assert len(ws) == 1 and prop(ws[0], 'Part0').text == middle.get('referent'), name_of(g)
        pred = M_mid @ cf_from_xml(prop(ws[0], 'C0')) @ inv(cf_from_xml(prop(ws[0], 'C1')))
        M = cf_from_xml(prop(g, 'CFrame'))
        max_err = max(max_err, np.abs(pred - M).max())
        for flag, want in (('Anchored', 'false'), ('CanCollide', 'false'), ('Massless', 'true')):
            assert prop(g, flag).text == want, (name_of(g), flag)
        assert prop(g, 'Material').text == str(fit.MATERIAL) and prop(g, 'Transparency').text == '0'
        parts.append(dict(shape=SHAPE_NAMES[int(prop(g, 'shape').text)], size=vec(prop(g, 'size')),
                          local=inv(M_mesh) @ M))
    pm = arms.hull_points(mesh)
    scale = mesh_scale(mesh)
    fit_numbers = report(parts, cell_hulls(pm, scale), (pm * scale)[:, 1].min() + 0.005, fit.TOP)
    print(f"{name_of(model)}: {len(gloves)} glove parts, weld/CFrame max err {max_err:.2e}, {fit_numbers}")
    ok &= (max_err < 1e-3 and fit_numbers['covered'] and fit_numbers['min_clearance'] >= MIN_CLEARANCE
           and fit_numbers['sticks_out_above_opening'] == 0)
print('PASS' if ok else 'FAIL')
sys.exit(0 if ok else 1)

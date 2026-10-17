# Muscular arms with gloves

`arms-with-gloves.rbxm` is the "Extremly Muscular" arm morph (`source/arms.rbxm`) with a
black leather glove and a charcoal wrist cuff added to each hand.

![preview](preview.png)

*(Preview: the white arm shape is rebuilt from the mesh's collision data, so its creases are
approximate. In Studio it renders with the real mesh.)*

## Using it

Drag `arms-with-gloves.rbxm` into Studio (or right-click a folder → Insert from File) and use
it wherever the original arms went. Nothing else changes:

- The gloves are plain `Part`s named `Glove` (hand) and `GloveCuff` (cuff), placed directly
  inside `BodyRightArm` / `BodyLeftArm` next to `color5` and `Middle`.
- Each one is already welded to `Middle`, the same way as the arm mesh. If your morph script
  re-welds every part in the arm model to `Middle`, it also picks up the gloves correctly.
- They're unanchored, `CanCollide`/`CanTouch`/`CanQuery` off and `Massless`, so they don't
  affect character physics.

To recolor them, select every `Glove` (or `GloveCuff`) part in the Explorer and change
`Color` / `Material`.

## How the gloves were fitted

The arm meshes themselves are hosted on Roblox, but the file stores each MeshPart's collision
hulls (`PhysicalConfigData`), including about 6,600 surface vertices per arm. `tools/gloves/fit.py`
measures the hand from those points and builds a rounded glove shell (0.05 studs over the
skin, 0.2-stud rounded edges) plus a cuff. `verify.py` then checks the written file: every
weld reproduces its part's position, and every hand point sits at least 0.03 studs inside
the glove.

Rebuild from the original (needs `cargo`, plus Python with `tools/gloves/requirements.txt`):

```sh
tools/gloves/build.sh
```

The glove sizes are at the top of `fit.py`. The colors and material are in
`tools/gloves/rbxtool/src/main.rs`.

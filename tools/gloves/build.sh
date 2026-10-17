#!/usr/bin/env bash
# Rebuilds arms-with-gloves.rbxm (and preview.png) from source/arms.rbxm.
# Needs: cargo, python3 with the packages in requirements.txt.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="${WORK_DIR:-$(mktemp -d)}"
py="${PYTHON:-python3}"

cargo build --release --quiet --manifest-path "$here/rbxtool/Cargo.toml"
tool="$here/rbxtool/target/release/rbxtool"

"$tool" toxml "$repo/source/arms.rbxm" "$work/arms.rbxmx"
"$py" "$here/fit.py" "$work/arms.rbxmx" "$work/gloves.json"
"$tool" gloves "$repo/source/arms.rbxm" "$work/gloves.json" "$work/arms-gloves.rbxm"
"$py" "$here/finalize.py" "$repo/source/arms.rbxm" "$work/arms-gloves.rbxm" "$repo/arms-with-gloves.rbxm"

"$tool" toxml "$repo/arms-with-gloves.rbxm" "$work/final.rbxmx"
"$py" "$here/verify.py" "$work/final.rbxmx"
"$py" "$here/render.py" "$work/final.rbxmx" "$repo/preview.png"

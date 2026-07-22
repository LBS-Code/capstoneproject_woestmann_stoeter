#!/usr/bin/env bash
set -euo pipefail

# Das Yarn-Repo im Basis-Image ist kaputt und laesst jedes apt-get update
# fehlschlagen. Wegschieben, wir brauchen Yarn nicht.
for file in /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
  [ -e "$file" ] || continue
  if grep -q "dl.yarnpkg.com" "$file"; then
    sudo mv "$file" "${file}.disabled"
  fi
done

sudo apt-get update

# ffmpeg  -> mediapy schreibt damit das Video
# libosmesa6(-dev) -> der Software-OpenGL-Kontext fuer MUJOCO_GL=osmesa
sudo apt-get install -y --no-install-recommends \
  ffmpeg \
  libosmesa6 \
  libosmesa6-dev

python -m pip install --upgrade pip
python -m pip install -r requirements.txt

# Wichtig: nicht nur importieren. Ein Import gelingt auch dann, wenn der
# GL-Kontext fehlt -- der Fehler kaeme erst mitten im Lauf beim ersten Frame.
python - <<'PY'
import os, mujoco, numpy as np
m = mujoco.MjModel.from_xml_string("<mujoco><worldbody><geom type='box' size='.1 .1 .1'/></worldbody></mujoco>")
d = mujoco.MjData(m)
mujoco.mj_forward(m, d)
r = mujoco.Renderer(m, height=64, width=64)
r.update_scene(d)
frame = r.render()
print(f"MUJOCO_GL={os.environ.get('MUJOCO_GL')}, mujoco {mujoco.__version__}, Testframe {frame.shape} -> Setup OK")
PY

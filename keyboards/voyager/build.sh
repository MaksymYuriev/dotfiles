#!/usr/bin/env bash
# Rebuild v2 firmware from source (needs git, make, arm-none-eabi-gcc, dfu-util).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -d qmk_zsa ] || git clone --depth 1 -b firmware25 https://github.com/zsa/qmk_firmware.git qmk_zsa
cd qmk_zsa
git submodule update --init --depth 1 --recursive lib/chibios lib/chibios-contrib lib/printf lib/pico-sdk
mkdir -p keyboards/zsa/voyager/keymaps/maksim_v2
for f in keymap.c config.h rules.mk keymap.json; do cp "$HERE/v2/$f" keyboards/zsa/voyager/keymaps/maksim_v2/; done
make zsa/voyager:maksim_v2
echo "Built: $(pwd)/zsa_voyager_maksim_v2.bin"

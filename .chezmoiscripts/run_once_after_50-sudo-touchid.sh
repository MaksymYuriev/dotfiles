#!/bin/bash
# Touch ID for sudo (survives macOS updates)
set -euo pipefail
if [ ! -f /etc/pam.d/sudo_local ]; then
  sed "s/^#auth/auth/" /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local >/dev/null
fi

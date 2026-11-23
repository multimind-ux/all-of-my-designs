#!/usr/bin/env bash
set -euo pipefail

# Install the Prompt SDDM login theme into the system theme directory.
# Run with sudo:  sudo ./install-sddm-theme.sh

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/sddm/elarun-custom"
DEST="/usr/share/sddm/themes/elarun-custom"

if [[ $EUID -ne 0 ]]; then
    echo "This script must run as root. Use: sudo $0" >&2
    exit 1
fi

install -d -m 0755 "$DEST"
cp -a "$SRC"/. "$DEST"/
chmod -R a+rX "$DEST"

mkdir -p /etc/sddm.conf.d
CONF="/etc/sddm.conf.d/50-prompt-theme.conf"
if [[ -f "$CONF" ]]; then
    cp "$CONF" "$CONF.bak.$(date +%Y%m%d-%H%M%S)"
fi
cat > "$CONF" <<'EOF'
[Theme]
Current=elarun-custom
EOF

echo "Prompt SDDM theme installed to $DEST"
echo "It will be used at the next login/reboot."

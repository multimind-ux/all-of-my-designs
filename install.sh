#!/usr/bin/env bash
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
qs_dir="$HOME/.config/quickshell"

mkdir -p "$qs_dir" "$qs_dir/assets/pixelbot" "$qs_dir/scripts" "$HOME/.local/bin" "$HOME/.local/share/fonts"

for config in wifi-panel notif-island wall-clock lockscreen; do
    rm -rf "$qs_dir/$config"
    cp -a "$src/quickshell/$config" "$qs_dir/$config"
done

cp "$src/assets/pixelbot/"*.wav "$qs_dir/assets/pixelbot/"
cp "$src/scripts/cava-"*.conf "$qs_dir/scripts/"
install -m 755 "$src/scripts/sync-caelestia-colors" "$HOME/.local/bin/sync-caelestia-colors"
install -m 755 "$src/scripts/wallcut" "$HOME/.local/bin/wallcut"
cp "$src/assets/fonts/Iceberg-Regular.ttf" "$HOME/.local/share/fonts/Iceberg-Regular.ttf"
fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true

# ── CachyOS screen saver ─────────────────────────────────────────────────────
ss_dir="$src/screensaver"
mkdir -p "$HOME/.config/hypr" "$HOME/.config/branding"

for dep in hypridle alacritty jq; do
    command -v "$dep" >/dev/null 2>&1 || echo "WARNING: $dep is missing"
done
command -v tte >/dev/null 2>&1 || echo "WARNING: tte is missing — run: uv tool install terminaltexteffects"

if [ -f "$HOME/.config/hypr/hypridle.conf" ]; then
    cp -a "$HOME/.config/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf.bak.$(date +%s)"
fi

install -m 755 "$ss_dir/screensaver" "$HOME/.local/bin/screensaver"
install -m 755 "$ss_dir/launch-screensaver" "$HOME/.local/bin/launch-screensaver"
install -m 755 "$ss_dir/idle-toggle" "$HOME/.local/bin/idle-toggle"
install -m 644 "$ss_dir/cachyos-logo.txt" "$HOME/.config/branding/cachyos.txt"
install -m 644 "$ss_dir/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user enable --now hypridle.service >/dev/null 2>&1 \
        || echo "WARNING: could not enable hypridle.service"
fi

echo "Installed Quickshell configs into $qs_dir"
echo "Installed CachyOS screen saver (hypridle + Alacritty + tte)"
echo "Now merge hyprland/execs-additions.lua and hyprland/keybinds-additions.lua into your Hyprland Lua config, then run: hyprctl reload"

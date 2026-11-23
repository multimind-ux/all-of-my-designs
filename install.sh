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

echo "Installed Quickshell configs into $qs_dir"
echo "Now merge hyprland/execs-additions.lua and hyprland/keybinds-additions.lua into your Hyprland Lua config, then run: hyprctl reload"

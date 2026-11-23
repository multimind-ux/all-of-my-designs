#!/usr/bin/env bash
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
qs_dir="$HOME/.config/quickshell"

mkdir -p "$qs_dir" "$qs_dir/assets/pixelbot" "$HOME/.local/bin"

for config in wifi-panel notif-island wall-clock lockscreen; do
    rm -rf "$qs_dir/$config"
    cp -a "$src/quickshell/$config" "$qs_dir/$config"
done

cp "$src/assets/pixelbot/"*.wav "$qs_dir/assets/pixelbot/"
install -m 755 "$src/scripts/sync-caelestia-colors" "$HOME/.local/bin/sync-caelestia-colors"

echo "Installed Quickshell configs into $qs_dir"
echo "Now merge hyprland/execs-additions.lua and hyprland/keybinds-additions.lua into your Hyprland Lua config, then run: hyprctl reload"

#!/usr/bin/env bash

temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

echo "🧪 Ejecutando $1 en entorno limpio..."
XDG_CONFIG_HOME="$temp_dir" \
XDG_CACHE_HOME="$temp_dir" \
XDG_DATA_HOME="$temp_dir" \
XDG_STATE_HOME="$temp_dir" \
nix run "nixpkgs#$1" -- "${@:2}"
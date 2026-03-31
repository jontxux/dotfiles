#!/usr/bin/env bash
set -euo pipefail

nix shell "nixpkgs#$1"
#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
build_root="${BUILD_ROOT:-${repo_root}/.build}"
source_root="${build_root}/checkout/src"

[[ -d "${source_root}" ]] || {
	echo "missing synchronized source tree: ${source_root}" >&2
	exit 1
}

# Git gives every freshly checked-out source the current time, making restored
# Ninja outputs look stale even when their command hashes match. Normalize only
# the source tree, before the out/Release cache is restored. The timestamp is
# Electron 11.3.0's release time, which predates every cached build output.
find "${source_root}" \
	-path '*/.git' -prune -o \
	-path "${source_root}/out" -prune -o \
	-type f -exec touch -d '@1613779153' {} +

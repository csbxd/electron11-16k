#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
build_root="${BUILD_ROOT:-${repo_root}/.build}"
checkout_root="${build_root}/checkout"
depot_tools_root="${build_root}/depot_tools"
dist_root="${repo_root}/dist"
sync_marker="${checkout_root}/.electron11-16k-synced"

export DEPOT_TOOLS_UPDATE=0
export PATH="${depot_tools_root}:${PATH}"

[[ -f "${sync_marker}" ]] || {
	echo "missing synchronized source marker: ${sync_marker}" >&2
	exit 1
}

mkdir -p "${dist_root}"
cd "${checkout_root}/src"
grep -q 'struct PageCharacteristics' \
	base/allocator/partition_allocator/page_allocator_constants.h
grep -q 'current_cpu == "arm64" && is_android' build/config/compiler/BUILD.gn

export CHROMIUM_BUILDTOOLS_PATH="${checkout_root}/src/buildtools"

gn gen out/Release --args='import("//electron/build/args/release.gn") target_cpu="arm64" clang_use_chrome_plugins=false fatal_linker_warnings=false enable_linux_installer=false symbol_level=0 blink_symbol_level=0'

ninja -C out/Release electron -j "$(nproc)"
python electron/script/strip-binaries.py \
	--directory out/Release --target-cpu arm64
ninja -C out/Release electron:electron_dist_zip -j "$(nproc)"

cp out/Release/dist.zip "${dist_root}/electron-v11.3.0-linux-arm64-16k.zip"

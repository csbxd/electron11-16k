#!/usr/bin/env bash
set -euo pipefail

readonly ELECTRON_VERSION="v11.3.0"
readonly DEPOT_TOOLS_REVISION="011cc41c3d07b1577de9e794adfb73591223a995"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
build_root="${BUILD_ROOT:-${repo_root}/.build}"
checkout_root="${build_root}/checkout"
depot_tools_root="${build_root}/depot_tools"
sync_marker="${checkout_root}/.electron11-16k-synced"

if [[ -f "${sync_marker}" ]]; then
	echo "using cached pinned Electron source tree"
	exit 0
fi

export DEPOT_TOOLS_UPDATE=0
export GIT_TERMINAL_PROMPT=0
export PATH="${depot_tools_root}:${PATH}"

mkdir -p "${build_root}" "${checkout_root}/src"

if [[ ! -d "${depot_tools_root}/.git" ]]; then
	git clone --filter=blob:none \
		https://chromium.googlesource.com/chromium/tools/depot_tools.git \
		"${depot_tools_root}"
fi
git -C "${depot_tools_root}" checkout --detach "${DEPOT_TOOLS_REVISION}"

if [[ ! -d "${checkout_root}/src/electron/.git" ]]; then
	git clone --depth=1 --branch "${ELECTRON_VERSION}" \
		https://github.com/electron/electron.git \
		"${checkout_root}/src/electron"
fi

cd "${checkout_root}"
gclient config \
	--name src/electron \
	--unmanaged \
	--custom-var=checkout_arm=True \
	--custom-var=checkout_arm64=True \
	--custom-var=download_external_binaries=False \
	https://github.com/electron/electron.git

ELECTRON_USE_THREE_WAY_MERGE_FOR_PATCHES=1 \
	gclient sync --no-history

cd "${checkout_root}/src"
patch --batch --forward -p1 \
	< "${repo_root}/patches/chromium-87-partitionalloc-linux-arm64-16k.patch"
patch --batch --forward -p1 \
	< "${repo_root}/patches/chromium-87-linux-arm64-link-alignment.patch"

grep -q 'struct PageCharacteristics' \
	base/allocator/partition_allocator/page_allocator_constants.h
grep -q 'current_cpu == "arm64" && is_android' build/config/compiler/BUILD.gn

touch "${sync_marker}"
du -sh "${checkout_root}" "${depot_tools_root}"

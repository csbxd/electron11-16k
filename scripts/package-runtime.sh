#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
dist_root="${repo_root}/dist"
source_zip="${dist_root}/electron-v11.3.0-linux-arm64-16k.zip"
stage_root="${dist_root}/runtime"
archive="${dist_root}/electron-v11.3.0-linux-arm64-16k.tar.xz"

[[ -f "${source_zip}" ]] || {
	echo "missing ${source_zip}" >&2
	exit 1
}

rm -rf "${stage_root}"
mkdir -p "${stage_root}"
unzip -q "${source_zip}" -d "${stage_root}"
chmod +x "${stage_root}/electron" "${stage_root}/chrome-sandbox"

python3 "${script_dir}/verify-runtime.py" "${stage_root}"

printf '%s\n' \
	'electron_version=11.3.0' \
	'chromium_version=87.0.4280.141' \
	'node_version=12.18.3' \
	'partitionalloc_backport=chromium-cl-3545665' \
	'link_alignment_backport=chromium-cl-3542265' \
	> "${stage_root}/BUILDINFO"

tar --sort=name --mtime='@1613779153' --owner=0 --group=0 --numeric-owner \
	-cJf "${archive}" -C "${stage_root}" .
sha256sum "${archive}" > "${archive}.sha256"

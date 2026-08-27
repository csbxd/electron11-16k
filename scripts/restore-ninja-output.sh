#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
build_root="${BUILD_ROOT:-${repo_root}/.build}"
release_root="${build_root}/checkout/src/out/Release"
ninja_log="${release_root}/.ninja_log"

if [[ ! -f "${ninja_log}" ]]; then
	echo "no partial Ninja output to refresh"
	exit 0
fi

restored_outputs=0
while IFS=$'\t' read -r _ _ _ output _; do
	[[ -n "${output}" && -e "${release_root}/${output}" ]] || continue
	touch "${release_root}/${output}"
	((restored_outputs += 1))
done < <(tail -n +2 "${ninja_log}" | sort -t $'\t' -k4,4 -u)

# Ninja's logs store output mtimes. Refresh both .ninja_log and .ninja_deps
# with the modern Ninja on the Ubuntu 24 host. Chromium 87's bundled Ninja
# predates the restat tool.
ninja -C "${release_root}" -t restat
echo "refreshed ${restored_outputs} cached Ninja outputs"

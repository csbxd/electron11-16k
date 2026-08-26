# Electron 11 for Linux ARM64 with 16 KiB pages

This repository reproducibly rebuilds Electron 11.3.0 for Linux ARM64 systems
whose kernels use 16 KiB pages, such as Asahi Linux. Electron 11 embeds
Chromium 87.0.4280.141, which assumes 4 KiB pages in PartitionAlloc and forces
4 KiB ELF segment alignment on Linux ARM64.

The build applies two upstream-derived backports:

- Chromium CL 3545665 makes the Chromium and PDFium PartitionAlloc copies use
  the runtime system page size. The patch is Fedora's Chromium 87 adaptation.
- Small follow-ups adapt the backport to Chromium 87's C++14 syntax while
  keeping its global page characteristics constant-initialized. The obsolete
  Chrome-only style plugin is disabled; normal compiler warnings remain fatal.
- Chromium CL 3542265 stops forcing 4 KiB linker pages on Linux ARM64. The
  small patch here is adapted to Chromium 87's older GN layout.

The resulting runtime keeps Electron 11's Node module ABI and legacy `remote`
API, so it can host applications that cannot move to a newer Electron.

## Reproducibility

The build pins:

- Electron: `v11.3.0`
- Chromium: `87.0.4280.141`
- PDFium: `0950ad89ea1123b71be05b3c5c4223c2934a976f`
- depot_tools: `011cc41c3d07b1577de9e794adfb73591223a995`
- build container: Ubuntu 18.04 with Chromium 87 build dependencies

Run the GitHub Actions workflow manually, or push a tag such as
`v11.3.0-16k.1`. Tagged builds create a GitHub Release containing
`electron-v11.3.0-linux-arm64-16k.tar.xz` and its SHA-256 checksum.

The historical Chromium checkout and a full optimized build can exceed one
standard GitHub-hosted runner's six-hour lifetime. CI therefore keeps source
sync and compilation on the same runner, limits each Ninja slice to two hours,
and resumes completed Ninja outputs from an exact-input Actions cache.

## Verification

CI checks every ELF `PT_LOAD` segment for at least 16 KiB alignment and the
required offset/address congruence. It then executes the ARM64 runtime on a
native GitHub ARM64 runner. Consumers should additionally run it on an actual
16 KiB kernel; the Gentoo `net-misc/baidunetdisk` package is the primary
consumer and performs that integration test.

Electron and Chromium retain their upstream licenses. The build scripts in
this repository are MIT licensed. The backport files retain their original
commit authorship and license context.

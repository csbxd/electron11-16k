#!/usr/bin/env python3
import argparse
import os
from pathlib import Path
import struct
import subprocess
import sys


ELF_HEADER = struct.Struct("<16sHHIQQQIHHHHHH")
PROGRAM_HEADER = struct.Struct("<IIQQQQQQ")
ELF_MAGIC = b"\x7fELF"
ELFCLASS64 = 2
ELFDATA2LSB = 1
EM_AARCH64 = 183
PT_LOAD = 1
MIN_PAGE_SIZE = 16384


def verify_elf(path: Path, require_aarch64: bool = True) -> int:
    data = path.read_bytes()
    if not data.startswith(ELF_MAGIC):
        return 0
    if data[4] != ELFCLASS64 or data[5] != ELFDATA2LSB:
        raise ValueError(f"{path}: expected ELF64 little-endian")

    header = ELF_HEADER.unpack_from(data)
    machine = header[2]
    phoff, phentsize, phnum = header[5], header[9], header[10]
    if require_aarch64 and machine != EM_AARCH64:
        raise ValueError(f"{path}: expected AArch64 machine, got {machine}")
    if phentsize != PROGRAM_HEADER.size:
        raise ValueError(f"{path}: unexpected program header size {phentsize}")

    load_count = 0
    for index in range(phnum):
        phdr = PROGRAM_HEADER.unpack_from(data, phoff + index * phentsize)
        kind, offset, vaddr, align = phdr[0], phdr[2], phdr[3], phdr[7]
        if kind != PT_LOAD:
            continue
        load_count += 1
        if align < MIN_PAGE_SIZE:
            raise ValueError(
                f"{path}: PT_LOAD alignment {align:#x} is below {MIN_PAGE_SIZE:#x}"
            )
        if offset % MIN_PAGE_SIZE != vaddr % MIN_PAGE_SIZE:
            raise ValueError(
                f"{path}: PT_LOAD offset {offset:#x} and address {vaddr:#x} "
                "are not congruent for 16 KiB pages"
            )

    if not load_count:
        raise ValueError(f"{path}: ELF has no PT_LOAD segments")
    return 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("runtime", type=Path)
    parser.add_argument("--run", action="store_true")
    args = parser.parse_args()

    electron = args.runtime / "electron"
    if not electron.is_file():
        raise SystemExit(f"missing {electron}")

    version_strings = electron.read_bytes()
    for marker in (b"Electron/11.3.0", b"Chrome/87.0.4280.141"):
        if marker not in version_strings:
            raise SystemExit(f"{electron}: missing version marker {marker!r}")

    elf_count = 0
    for path in sorted(args.runtime.rglob("*")):
        if path.is_file():
            elf_count += verify_elf(path)
    if elf_count < 8:
        raise SystemExit(f"only found {elf_count} ELF files; runtime is incomplete")

    if args.run:
        environment = os.environ.copy()
        environment.setdefault("ELECTRON_DISABLE_SANDBOX", "1")
        completed = subprocess.run(
            [str(electron), "--no-sandbox", "--version"],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            env=environment,
        )
        if "v11.3.0" not in completed.stdout:
            raise SystemExit(f"unexpected runtime version: {completed.stdout!r}")

    print(f"verified {elf_count} AArch64 ELF files with 16 KiB-safe PT_LOAD segments")
    return 0


if __name__ == "__main__":
    sys.exit(main())

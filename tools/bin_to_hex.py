#!/usr/bin/env python3
import sys
from pathlib import Path

def main():
    if len(sys.argv) != 3:
        print("Usage: bin_to_hex.py input.bin output.hex")
        sys.exit(1)

    in_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])

    data = in_path.read_bytes()

    if len(data) % 4 != 0:
        data += b"\x00" * (4 - (len(data) % 4))

    lines = []

    for i in range(0, len(data), 4):
        word_bytes = data[i:i+4]

        # RISC-V is little-endian in memory.
        # $readmemh loads each line as a 32-bit word.
        # So bytes 93 00 50 00 should become hex line 00500093.
        word = int.from_bytes(word_bytes, byteorder="little")
        lines.append(f"{word:08x}")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines) + "\n")

if __name__ == "__main__":
    main()
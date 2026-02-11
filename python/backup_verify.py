#!/usr/bin/env python3
import argparse
from pathlib import Path
import sys

def main():
    p = argparse.ArgumentParser(description="Verify latest backup archive exists and is not empty.")
    p.add_argument("--backup-dir", required=True, help="Backup directory, e.g. ./backups")
    args = p.parse_args()

    bdir = Path(args.backup_dir).expanduser().resolve()
    if not bdir.exists() or not bdir.is_dir():
        print(f"❌ Backup dir not found: {bdir}")
        return 1

    archives = sorted(bdir.glob("*.tar.gz"), key=lambda x: x.stat().st_mtime, reverse=True)
    if not archives:
        print(f"❌ No .tar.gz archives found in: {bdir}")
        return 2

    latest = archives[0]
    size = latest.stat().st_size

    print(f"Latest backup: {latest.name}")
    print(f"Path: {latest}")
    print(f"Size: {size} bytes")

    if size <= 0:
        print("❌ Latest archive is empty.")
        return 3

    print("✅ Backup verification passed.")
    return 0

if __name__ == "__main__":
    sys.exit(main())

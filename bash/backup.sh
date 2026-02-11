#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./backup.sh <source_path> [backup_dir]
#
# Examples:
#   ./backup.sh /etc ./backups
#   ./backup.sh /var/www/html ./backups

SRC="${1:-/etc}"
BACKUP_DIR="${2:-./backups}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$LOG_DIR" "$BACKUP_DIR"
LOG_FILE="$LOG_DIR/backup.log"

ts() { date "+%Y-%m-%d %H:%M:%S"; }

STAMP="$(date "+%Y%m%d-%H%M%S")"
NAME="$(basename "$SRC" | tr -cd '[:alnum:]_-')"
ARCHIVE="$BACKUP_DIR/${NAME}-${STAMP}.tar.gz"

echo "[$(ts)] === BACKUP START ===" | tee -a "$LOG_FILE"
echo "[$(ts)] Source: $SRC" | tee -a "$LOG_FILE"
echo "[$(ts)] Output: $ARCHIVE" | tee -a "$LOG_FILE"

if [ ! -e "$SRC" ]; then
  echo "[$(ts)] ❌ Source path does not exist: $SRC" | tee -a "$LOG_FILE"
  exit 1
fi

tar -czf "$ARCHIVE" "$SRC" 2>>"$LOG_FILE"

if [ -s "$ARCHIVE" ]; then
  echo "[$(ts)] ✅ Backup created successfully: $ARCHIVE" | tee -a "$LOG_FILE"
  ls -lh "$ARCHIVE" | tee -a "$LOG_FILE"
else
  echo "[$(ts)] ❌ Backup failed (archive empty): $ARCHIVE" | tee -a "$LOG_FILE"
  exit 1
fi

echo "[$(ts)] === BACKUP END ===" | tee -a "$LOG_FILE"

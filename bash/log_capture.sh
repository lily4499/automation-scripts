#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./log_capture.sh <service_name> [since]
#
# Examples:
#   ./log_capture.sh nginx "1 hour ago"
#   ./log_capture.sh docker "30 min ago"

SERVICE="${1:-nginx}"
SINCE="${2:-1 hour ago}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_DIR="$ROOT_DIR/incident-bundles"
LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$BUNDLE_DIR" "$LOG_DIR"

LOG_FILE="$LOG_DIR/log-capture.log"
ts() { date "+%Y-%m-%d %H:%M:%S"; }

STAMP="$(date "+%Y%m%d-%H%M%S")"
OUT="$BUNDLE_DIR/${SERVICE}-bundle-${STAMP}"
mkdir -p "$OUT"

echo "[$(ts)] === LOG CAPTURE START ===" | tee -a "$LOG_FILE"
echo "[$(ts)] Service: $SERVICE | Since: $SINCE" | tee -a "$LOG_FILE"
echo "[$(ts)] Output folder: $OUT" | tee -a "$LOG_FILE"

# System info
{
  echo "=== DATE ==="
  date
  echo
  echo "=== HOSTNAME ==="
  hostname
  echo
  echo "=== UPTIME ==="
  uptime || true
  echo
  echo "=== DISK ==="
  df -h || true
  echo
  echo "=== MEMORY ==="
  free -m || true
  echo
  echo "=== TOP (brief) ==="
  ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 20 || true
} > "$OUT/system-info.txt"

# Service status
systemctl status "$SERVICE" --no-pager > "$OUT/service-status.txt" 2>&1 || true

# Recent logs via journalctl
journalctl -u "$SERVICE" --since "$SINCE" --no-pager > "$OUT/journalctl.txt" 2>&1 || true

# Common log files snapshot (best effort)
for f in /var/log/syslog /var/log/messages /var/log/auth.log /var/log/kern.log; do
  if [ -f "$f" ]; then
    tail -n 500 "$f" > "$OUT/$(basename "$f").tail500.txt" 2>/dev/null || true
  fi
done

# Network snapshot
ss -tulnp > "$OUT/ss-tulnp.txt" 2>&1 || true

# Package the bundle
tar -czf "${OUT}.tar.gz" -C "$BUNDLE_DIR" "$(basename "$OUT")" 2>>"$LOG_FILE" || true

echo "[$(ts)] ✅ Bundle created: $OUT" | tee -a "$LOG_FILE"
echo "[$(ts)] ✅ Bundle archive: ${OUT}.tar.gz" | tee -a "$LOG_FILE"
echo "[$(ts)] === LOG CAPTURE END ===" | tee -a "$LOG_FILE"

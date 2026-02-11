#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./service_recovery.sh <service_name>
#
# Example:
#   ./service_recovery.sh nginx

SERVICE="${1:-nginx}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/recovery.log"

ts() { date "+%Y-%m-%d %H:%M:%S"; }

echo "[$(ts)] === SERVICE RECOVERY START ===" | tee -a "$LOG_FILE"
echo "[$(ts)] Target service: $SERVICE" | tee -a "$LOG_FILE"

echo "[$(ts)] Current status (before):" | tee -a "$LOG_FILE"
systemctl status "$SERVICE" --no-pager | head -n 25 | tee -a "$LOG_FILE" || true

if systemctl is-active --quiet "$SERVICE"; then
  echo "[$(ts)] ✅ Service already running. Doing a safe restart anyway." | tee -a "$LOG_FILE"
else
  echo "[$(ts)] ❌ Service is down. Attempting start." | tee -a "$LOG_FILE"
fi

sudo systemctl restart "$SERVICE" 2>>"$LOG_FILE" || systemctl restart "$SERVICE" 2>>"$LOG_FILE" || true
sleep 2

if systemctl is-active --quiet "$SERVICE"; then
  echo "[$(ts)] ✅ Recovery success: $SERVICE is active" | tee -a "$LOG_FILE"
else
  echo "[$(ts)] ❌ Recovery failed: $SERVICE is still not active" | tee -a "$LOG_FILE"
  systemctl status "$SERVICE" --no-pager | tail -n 60 | tee -a "$LOG_FILE" || true
  journalctl -u "$SERVICE" --since "15 min ago" --no-pager | tail -n 80 | tee -a "$LOG_FILE" || true
  exit 1
fi

echo "[$(ts)] Status (after):" | tee -a "$LOG_FILE"
systemctl status "$SERVICE" --no-pager | head -n 25 | tee -a "$LOG_FILE" || true

echo "[$(ts)] === SERVICE RECOVERY END ===" | tee -a "$LOG_FILE"

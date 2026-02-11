#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./health_check.sh [service_name] [port] [url]
#
# Examples:
#   ./health_check.sh nginx 80 http://localhost
#   ./health_check.sh myapp 8080 http://localhost:8080/health

SERVICE="${1:-nginx}"
PORT="${2:-80}"
URL="${3:-http://localhost}"

LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/health-check.log"

ts() { date "+%Y-%m-%d %H:%M:%S"; }

echo "[$(ts)] === HEALTH CHECK START ===" | tee -a "$LOG_FILE"
echo "[$(ts)] Service: $SERVICE | Port: $PORT | URL: $URL" | tee -a "$LOG_FILE"

# 1) Service status
if systemctl is-active --quiet "$SERVICE"; then
  echo "[$(ts)] ✅ service is active: $SERVICE" | tee -a "$LOG_FILE"
else
  echo "[$(ts)] ❌ service is NOT active: $SERVICE" | tee -a "$LOG_FILE"
  systemctl status "$SERVICE" --no-pager | tail -n 30 | tee -a "$LOG_FILE" || true
fi

# 2) Port listening
if ss -tulnp 2>/dev/null | grep -qE "[:.]$PORT\b"; then
  echo "[$(ts)] ✅ port is listening: $PORT" | tee -a "$LOG_FILE"
else
  echo "[$(ts)] ❌ port is NOT listening: $PORT" | tee -a "$LOG_FILE"
  ss -tulnp 2>/dev/null | head -n 50 | tee -a "$LOG_FILE" || true
fi

# 3) HTTP check (best effort)
if command -v curl >/dev/null 2>&1; then
  if curl -fsS --max-time 5 "$URL" >/dev/null; then
    echo "[$(ts)] ✅ curl check passed: $URL" | tee -a "$LOG_FILE"
  else
    echo "[$(ts)] ❌ curl check failed: $URL" | tee -a "$LOG_FILE"
    curl -v --max-time 5 "$URL" 2>&1 | tail -n 40 | tee -a "$LOG_FILE" || true
  fi
else
  echo "[$(ts)] ⚠️ curl not found, skipping HTTP check" | tee -a "$LOG_FILE"
fi

echo "[$(ts)] === HEALTH CHECK END ===" | tee -a "$LOG_FILE"

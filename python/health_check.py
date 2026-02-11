#!/usr/bin/env python3
import argparse
import time
import urllib.request
import urllib.error
import sys

def check_url(url: str, timeout: int) -> int:
    start = time.time()
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "ops-health-check/1.0"})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            status = resp.getcode()
            elapsed_ms = int((time.time() - start) * 1000)
            print(f"✅ OK: {url} | status={status} | time={elapsed_ms}ms")
            return 0 if 200 <= status < 400 else 2
    except urllib.error.HTTPError as e:
        elapsed_ms = int((time.time() - start) * 1000)
        print(f"❌ HTTP ERROR: {url} | status={e.code} | time={elapsed_ms}ms")
        return 2
    except Exception as e:
        elapsed_ms = int((time.time() - start) * 1000)
        print(f"❌ FAIL: {url} | error={e} | time={elapsed_ms}ms")
        return 2

def main():
    p = argparse.ArgumentParser(description="Simple HTTP health check (no external deps).")
    p.add_argument("--url", required=True, help="URL to check, e.g. http://localhost:8080/health")
    p.add_argument("--timeout", type=int, default=5, help="Timeout seconds (default: 5)")
    args = p.parse_args()
    sys.exit(check_url(args.url, args.timeout))

if __name__ == "__main__":
    main()

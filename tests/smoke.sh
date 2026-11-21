#!/usr/bin/env bash
# Smoke-test a running instance of the site.
# Usage: tests/smoke.sh [base_url]   (default http://localhost:8080)
set -euo pipefail

BASE="${1:-http://localhost:8080}"
fail=0

check() {
  local name="$1"; shift
  if "$@"; then echo "✓ $name"; else echo "✗ $name"; fail=1; fi
}

status() { curl -s -o /dev/null -w '%{http_code}' "$BASE$1"; }

# Wait up to 15s for the server to come up.
for _ in $(seq 1 30); do
  curl -sf "$BASE/healthz" >/dev/null && break
  sleep 0.5
done

check "home page returns 200"           test "$(status /)" = 200
check "home page has the title"         bash -c "curl -s '$BASE/' | grep -q '<title>DevOps CI/CD Demo</title>'"
check "stylesheet returns 200"          test "$(status /css/style.css)" = 200
check "favicon returns 200"             test "$(status /favicon.svg)" = 200
check "/version.json has a commit"      bash -c "curl -s '$BASE/version.json' | grep -q '\"commit\"'"
check "/healthz returns ok"             bash -c "curl -s '$BASE/healthz' | grep -qx ok"
check "unknown page returns 404"        test "$(status /does-not-exist)" = 404
check "404 uses the custom page"        bash -c "curl -s '$BASE/does-not-exist' | grep -q 'page not found'"
check "CSP header on HTML"              bash -c "curl -s -D - -o /dev/null '$BASE/' | grep -qi '^content-security-policy:'"
check "CSP header on CSS"               bash -c "curl -s -D - -o /dev/null '$BASE/css/style.css' | grep -qi '^content-security-policy:'"
check "CSS is cached"                   bash -c "curl -s -D - -o /dev/null '$BASE/css/style.css' | grep -qi '^cache-control:.*max-age'"
check "nginx version is hidden"         bash -c "! curl -s -D - -o /dev/null '$BASE/' | grep -qi '^server: nginx/'"
check "CSS is gzipped"                  bash -c "curl -s -H 'Accept-Encoding: gzip' -D - -o /dev/null '$BASE/css/style.css' | grep -qi '^content-encoding: gzip'"

exit "$fail"

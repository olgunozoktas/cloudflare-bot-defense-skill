#!/usr/bin/env bash
# edge-check.sh — ask a site's pages and machine paths over HTTP/2 and HTTP/1.1, and show which
# answers Cloudflare challenged. It only reads (GET requests); it changes nothing.
#
# Usage: tools/edge-check.sh <https://site> [extra path ...]
# Exit:  0 = pages pass over HTTP/2 and the machine paths are not challenged over HTTP/1.1
#        1 = at least one expectation failed (each FAIL line names it)
#        2 = bad usage, or curl is missing
set -u

usage() {
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then usage; exit 0; fi
if [ $# -lt 1 ]; then usage >&2; exit 2; fi
command -v curl >/dev/null 2>&1 || { echo "edge-check: curl is missing" >&2; exit 2; }

site="${1%/}"; shift
pages=("/")
machine=("/robots.txt" "/sitemap.xml" "/.well-known/security.txt")
extra=("$@")
fail=0

# ask <version flag> <path> -> prints "<status> <challenge|->"
ask() {
  local headers status mitigated
  headers=$(curl -s "$1" -o /dev/null -D - -A "edge-check/1.0" --max-time 20 "$site$2")
  status=$(printf '%s\n' "$headers" | awk 'toupper($1) ~ /^HTTP\// {code=$2} END {print code}')
  mitigated=$(printf '%s\n' "$headers" | tr -d '\r' | awk -F': *' 'tolower($1)=="cf-mitigated" {print $2}')
  printf '%s %s\n' "${status:-000}" "${mitigated:--}"
}

check() { # check <label> <flag> <path> <want: pass|challenge|any>
  local out status mitigated verdict="ok"
  out=$(ask "$2" "$3"); status=${out%% *}; mitigated=${out#* }
  case "$4" in
    pass)      [ "$mitigated" = "-" ] && [ "${status:0:1}" != "5" ] || verdict="FAIL" ;;
    challenge) [ "$mitigated" = "challenge" ] || verdict="FAIL" ;;
  esac
  [ "$verdict" = "FAIL" ] && fail=1
  printf '%-4s %-8s %-6s %-34s status=%s cf-mitigated=%s (want %s)\n' \
    "$verdict" "$1" "${2#--}" "$3" "$status" "$mitigated" "$4"
}

for p in "${pages[@]}"; do
  check page --http2 "$p" pass
  check page --http1.1 "$p" any
done
for p in "${machine[@]}" ${extra[@]+"${extra[@]}"}; do
  check machine --http1.1 "$p" pass
done
check probe --http2 "/wp-login.php" any

exit "$fail"

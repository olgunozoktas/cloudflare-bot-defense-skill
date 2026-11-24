#!/usr/bin/env bash
# Tests of tools/edge-check.sh with a fake curl (an exported bash function): no network, no files.
# Run: bash tests/edge-check.test.sh   Exit 0 = every test passed.
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
script="$here/tools/edge-check.sh"
failures=0

# The fake curl answers from FAKE_CHALLENGE_PATHS (space-separated paths that get a challenge)
# and FAKE_STATUS (the status of every other answer).
curl() {
  local url="${!#}" path
  path="/${url#*://*/}"
  [ "$url" = "${url#*://*/}" ] && path="/"
  if [[ " ${FAKE_CHALLENGE_PATHS:-} " == *" $path "* ]]; then
    printf 'HTTP/2 403\r\ncf-mitigated: challenge\r\n\r\n'
  else
    printf 'HTTP/2 %s\r\nserver: cloudflare\r\n\r\n' "${FAKE_STATUS:-200}"
  fi
}
export -f curl

expect() { # expect <name> <want exit> <command...>
  local name="$1" want="$2" got out; shift 2
  out=$("$@" 2>&1); got=$?
  if [ "$got" = "$want" ]; then echo "PASS $name"; else
    echo "FAIL $name: exit $got, want $want"; printf '%s\n' "$out" | sed 's/^/    /'; failures=$((failures + 1)); fi
}

expect "no argument is a usage error" 2 bash "$script"
expect "-h prints the usage" 0 bash "$script" -h
expect "clean site passes" 0 env FAKE_CHALLENGE_PATHS="" bash "$script" https://site.test
expect "a challenged page over HTTP/2 fails" 1 env FAKE_CHALLENGE_PATHS="/" bash "$script" https://site.test
expect "a challenged machine path fails" 1 env FAKE_CHALLENGE_PATHS="/robots.txt" bash "$script" https://site.test
expect "a challenged extra path fails" 1 env FAKE_CHALLENGE_PATHS="/hook" bash "$script" https://site.test /hook
expect "a 5xx page fails" 1 env FAKE_STATUS=502 bash "$script" https://site.test
expect "a challenged probe is fine" 0 env FAKE_CHALLENGE_PATHS="/wp-login.php" bash "$script" https://site.test

out=$(FAKE_CHALLENGE_PATHS="/robots.txt" bash "$script" https://site.test 2>&1)
if printf '%s\n' "$out" | grep -q '^FAIL machine  http1.1 /robots.txt'; then echo "PASS the FAIL line names the path"
else echo "FAIL the FAIL line names the path"; failures=$((failures + 1)); fi

echo "failures=$failures"
[ "$failures" -eq 0 ]

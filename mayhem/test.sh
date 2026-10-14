#!/usr/bin/env bash
#
# mayhem/test.sh — BEHAVIORAL oracle for openkruise's workloadspread.NestedField. Runs the
# dynamically-linked KAT probe (/mayhem/ws_kat, built by build.sh) that looks up fixed paths in
# a fixed nested map/slice object through the real NestedField and asserts the exact values
# (and that out-of-range / missing paths are errors).
#
# Not `go test` alone: a Go test binary is statically linked, so the gate's LD_PRELOAD sabotage
# shim cannot neuter it. The KAT probe is cgo-linked (dynamic), so when the program is neutered
# to _exit(0) it prints nothing, every assertion below misses, and test.sh FAILS (§6.3).
#
# Emits a CTRF summary; exits non-zero iff failed>0.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
cd "${SRC:-/mayhem}"

emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-${SRC:-/mayhem}/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

PROBE=/mayhem/ws_kat
passed=0; failed=0

# Unconditional: a missing probe is a build.sh bug — FAIL loudly, never skip.
if [ ! -x "$PROBE" ]; then
  echo "FAIL: KAT probe $PROBE missing or not executable (build.sh should have produced it)" >&2
  emit_ctrf "openkruise-nestedfield-kat" 0 1
  exit 1
fi

OUT="$("$PROBE" 2>/dev/null)"
echo "--- KAT probe output ---"; printf '%s\n' "$OUT"; echo "------------------------"

assert() { # <desc> <expected-line>
  if printf '%s\n' "$OUT" | grep -qxF "$2"; then
    echo "PASS: $1"; passed=$((passed+1))
  else
    echo "FAIL: $1 (expected exact line: $2)"; failed=$((failed+1))
  fi
}

assert "spec.subsets.1.name == zone-b"      "KAT_0_OUT=zone-b"
assert "spec.subsets.0.replicas == 3"       "KAT_1_OUT=3"
assert "subsets index 2 is out of range"    "KAT_2_OUT=error"
assert "subsets index -1 is out of range"   "KAT_3_OUT=error"
assert "missing path is an error"           "KAT_4_OUT=error"

emit_ctrf "openkruise-nestedfield-kat" "$passed" "$failed"

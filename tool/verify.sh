#!/usr/bin/env bash
set -euo pipefail

echo "== muxa_xtream verify =="

# Controls: set VERIFY_PUB_GET=1 to run pub get; default is skip to avoid
# network in constrained environments.
: "${VERIFY_PUB_GET:=0}"

has_cmd() { command -v "$1" >/dev/null 2>&1; }

FAILED=0
FAILED_TASKS=()

run_task() {
  local name="$1"; shift
  if "$@"; then
    echo "✅ ${name}"
  else
    echo "❌ ${name} failed"
    FAILED=1
    FAILED_TASKS+=("${name}")
  fi
}

runner_override=${VERIFY_RUNNER:-}
# Default to Dart to avoid requiring Flutter devices
runner="dart"
if [[ -n "$runner_override" ]]; then
  runner="$runner_override"
elif ! has_cmd dart && has_cmd flutter; then
  runner="flutter"
fi

echo "Tooling: using ${runner}"
if ! has_cmd "${runner}"; then
  echo "Error: runner '${runner}' not found in PATH" >&2
  exit 127
fi
"${runner}" --version 2>/dev/null || true

if [[ "${VERIFY_PUB_GET}" == "1" ]]; then
  if [[ "${runner}" == "flutter" ]]; then
    run_task "flutter pub get" flutter pub get
  else
    run_task "dart pub get" dart pub get
  fi
else
  echo "Skipping pub get (set VERIFY_PUB_GET=1 to enable)"
fi

echo "Formatting..."
run_task "dart format" dart format .

echo "Formatting check..."
run_task "dart format check" dart format --output=none --set-exit-if-changed .

echo "Static analysis..."
run_task "dart analyze" dart analyze

echo "Running tests..."

has_tests() {
  [ -d test ] && find test -type f -name "*_test.dart" -print -quit | grep -q .
}

if ! has_tests; then
  echo "No tests found; skipping test step."
else
  # Prefer Dart tests for pure Dart package
  : "${VERIFY_COVERAGE:=0}"
  if [[ "${VERIFY_COVERAGE}" == "1" ]]; then
    run_task "dart test --coverage" bash -lc 'dart test --coverage=coverage'
  else
    run_task "dart test" dart test
  fi
fi

if [[ ${FAILED} -ne 0 ]]; then
  echo ""
  echo "Some checks failed:" >&2
  for t in "${FAILED_TASKS[@]}"; do
    echo " - ${t}" >&2
  done
  exit 1
fi

echo "All done."

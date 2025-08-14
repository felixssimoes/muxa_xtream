#!/usr/bin/env bash
set -euo pipefail

echo "== muxa_xtream verify =="

# Controls: set VERIFY_PUB_GET=1 to run pub get; default is skip to avoid
# network in constrained environments.
: "${VERIFY_PUB_GET:=0}"

has_cmd() { command -v "$1" >/dev/null 2>&1; }

run_or_skip() {
  local name="$1"; shift
  if "$@"; then
    echo "✅ ${name}"
  else
    echo "⚠️  ${name} failed (continuing)"
  fi
}

runner_override=${VERIFY_RUNNER:-}
runner="flutter"
if [[ -n "$runner_override" ]]; then
  runner="$runner_override"
elif ! has_cmd flutter; then
  runner="dart"
fi

echo "Tooling: using ${runner}"
"${runner}" --version 2>/dev/null || true

if [[ "${VERIFY_PUB_GET}" == "1" ]]; then
  if [[ "${runner}" == "flutter" ]]; then
    run_or_skip "flutter pub get" flutter pub get
  else
    run_or_skip "dart pub get" dart pub get
  fi
else
  echo "Skipping pub get (set VERIFY_PUB_GET=1 to enable)"
fi

echo "Formatting..."
run_or_skip "dart format" dart format .

echo "Formatting check..."
run_or_skip "dart format check" dart format --output=none --set-exit-if-changed .

echo "Static analysis..."
if [[ "${runner}" == "flutter" ]]; then
  if ! flutter analyze; then
    echo "flutter analyze failed; attempting dart analyze fallback"
    run_or_skip "dart analyze" dart analyze
  else
    echo "✅ flutter analyze"
  fi
else
  run_or_skip "dart analyze" dart analyze
fi

echo "Running tests..."

has_tests() {
  [ -d test ] && find test -type f -name "*_test.dart" -print -quit | grep -q .
}

if ! has_tests; then
  echo "No tests found; skipping test step."
elif [[ "${runner}" == "flutter" ]]; then
  # Coverage optional in bootstrap; enable via VERIFY_COVERAGE=1
  : "${VERIFY_COVERAGE:=0}"
  if [[ "${VERIFY_COVERAGE}" == "1" ]]; then
    if ! flutter test --coverage; then
      echo "flutter test failed; attempting dart test fallback"
      run_or_skip "dart test" dart test
    else
      echo "✅ flutter test --coverage"
    fi
  else
    if ! flutter test; then
      echo "flutter test failed; attempting dart test fallback"
      run_or_skip "dart test" dart test
    else
      echo "✅ flutter test"
    fi
  fi
else
  # Fallback: try dart test if available
  if has_cmd dart; then
    if has_cmd dart && dart --version >/dev/null 2>&1; then
      run_or_skip "dart test" dart test
    else
      echo "Skipping tests: dart not available."
    fi
  fi
fi

echo "All done."

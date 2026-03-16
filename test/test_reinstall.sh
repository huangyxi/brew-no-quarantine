#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
init_test

print_group "reinstall"

print_test "reinstall default"
brew install --cask "$TEST_CASK" 2>/dev/null || true
add_quarantine "$TEST_APP"
run_bnq reinstall "$TEST_CASK"
[[ -d "$TEST_APP" ]] && ! has_quarantine "$TEST_APP"
report $?

print_test "--dry-run prints 'Would remove quarantine'"
brew install --cask "$TEST_CASK" 2>/dev/null || true
add_quarantine "$TEST_APP"
dry_out=$(run_bnq reinstall -n "$TEST_CASK" 2>&1 || true)
echo "$dry_out" | grep -q "Would remove quarantine"
report $?

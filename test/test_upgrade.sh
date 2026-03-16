#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
init_test

print_group "upgrade"

print_test "upgrade explicit <cask>"
brew install --cask "$TEST_CASK"
[[ -d "$TEST_APP" ]] && add_quarantine "$TEST_APP"

update_tap_to_v2
run_bnq upgrade "$TEST_CASK"
[[ -d "$TEST_APP" ]] && ! has_quarantine "$TEST_APP"
report $?

print_test "upgrade no cask argument"
revert_tap_to_v1
brew install --cask "$TEST_CASK"
[[ -d "$TEST_APP" ]] && add_quarantine "$TEST_APP"

update_tap_to_v2
run_bnq upgrade
[[ -d "$TEST_APP" ]] && ! has_quarantine "$TEST_APP"
report $?

print_test "upgrade --greedy"
run_bnq upgrade --greedy &>/dev/null
report $?

print_test "upgrade --greedy-auto-updates"
run_bnq upgrade --greedy-auto-updates &>/dev/null
report $?

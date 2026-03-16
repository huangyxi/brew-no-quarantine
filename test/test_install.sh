#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
init_test

print_group "install"

print_test "install default"
run_bnq install "$TEST_CASK"
[[ -d "$TEST_APP" ]] && ! has_quarantine "$TEST_APP"
report $?

#!/usr/bin/env bash
# Integration tests for brew-no-quarantine
# Usage: ./test/main.sh
# Requirements: macOS + Homebrew installed

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

echo "======================================================"
echo " brew-no-quarantine — integration tests"
echo "======================================================"

if ! command -v brew &>/dev/null; then
	echo "ERROR: Homebrew not found. Aborting." >&2
	exit 1
fi

SCRIPT_PASS=0
SCRIPT_FAIL=0

export GROUP_NUM=0
export BNQ_STATE_FILE
BNQ_STATE_FILE=$(mktemp)

for test_script in "${SCRIPT_DIR}"/test_*.sh; do
    [[ -e "$test_script" ]] || continue
    report info "Running $(basename "$test_script") ..."
    if bash "$test_script"; then
        ((SCRIPT_PASS+=1))
    else
        ((SCRIPT_FAIL+=1))
    fi
    if [[ -f "$BNQ_STATE_FILE" ]]; then
        source "$BNQ_STATE_FILE"
        rm -f "$BNQ_STATE_FILE"
    fi
done

echo ""
echo "======================================================"
printf " Suite Results: "
green "$SCRIPT_PASS test scripts passed"
printf "                "
if [[ "$SCRIPT_FAIL" -gt 0 ]]; then
    red "$SCRIPT_FAIL test scripts failed"
else
    green "0 test scripts failed"
fi
echo "======================================================"

[[ "$SCRIPT_FAIL" -eq 0 ]]

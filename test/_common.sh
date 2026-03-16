#!/usr/bin/env bash

set -uo pipefail

export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_ENV_HINTS=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BNQ="$(cd "$SCRIPT_DIR/.." && pwd)/brew-no-quarantine"

PASS=0
FAIL=0
GROUP_NUM=${GROUP_NUM:-0}
TEST_NUM=0
TEST_CHARS=(a b c d e f g h i j k l m n o p q r s t u v w x y z)
CURR_ID=""
CURR_TEST_NAME=""

TAP_DIR=""
ZIP_DIR=""
TEST_APP="/Applications/BnqTestApp.app"
TEST_TAP="bnq-test/local"
TEST_CASK="${TEST_TAP}/bnq-test-app"

green() { printf "\033[0;32m%s\033[0m\n" "$*"; }
red() { printf "\033[0;31m%s\033[0m\n" "$*"; }
yellow() { printf "\033[0;33m%s\033[0m\n" "$*"; }

report() {
	local status="$1"
	local msg="${2:-$CURR_TEST_NAME}"

	# If first arg is numeric, treat as exit code
	if [[ "$status" =~ ^[0-9]+$ ]]; then
		if [[ "$status" -eq 0 ]]; then
			status="success"
		else
			status="fail"
		fi
	fi

	local prefix=""
	[[ -n "${CURR_ID:-}" ]] && prefix="${CURR_ID}: "

	case "$status" in
		"success")
			green "  ✓ SUCCESS: ${prefix}${msg}"
			((PASS+=1))
			;;
		"fail")
			red "  ✗ FAIL: ${prefix}${msg}"
			((FAIL+=1))
			if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
				echo "::error::Test Fail: ${prefix}${msg}"
			fi
			;;
		"info")
			yellow "  → info: ${prefix}${msg}"
			;;
		*)
			yellow "  ? $status: ${prefix}${msg}"
			;;
	esac
}

print_group() {
	((GROUP_NUM+=1))
	TEST_NUM=0
	CURR_ID=""
	CURR_TEST_NAME=""
	echo ""
	echo "=== Group ${GROUP_NUM}: $1 ==="
}

cleanup_test() {
	if [[ -n "$TEST_CASK" ]]; then
		brew uninstall --cask "$TEST_CASK" 2>/dev/null || true
	fi
	if [[ -d "$TEST_APP" ]]; then
		rm -rf "$TEST_APP" 2>/dev/null || true
	fi
}

print_test() {
	local char="${TEST_CHARS[$TEST_NUM]}"
	((TEST_NUM+=1))
	CURR_ID="${GROUP_NUM}${char}"
	CURR_TEST_NAME="$1"
	echo "--- ${CURR_ID}: ${CURR_TEST_NAME} ---"

	cleanup_test
}

# Run brew-no-quarantine in the Homebrew Ruby environment
run_bnq() {
	brew ruby -- "$BNQ" "$@"
}

has_quarantine() {
	xattr "$1" 2>/dev/null | grep -q "com.apple.quarantine"
}

# Manually stamp a quarantine attribute (simulates macOS gating a downloaded app)
add_quarantine() {
	xattr -w com.apple.quarantine "0182;65f00001;Safari;" "$1" 2>/dev/null || true
}

# Creates a self-contained Homebrew tap with a fake BnqTestApp.app cask.
# v1 and v2 point to local file:// zip archives so no internet is needed.
setup_local_tap() {
	report info "Creating local tap with fake cask v1.0 ..."

	TAP_DIR="$(mktemp -d)/homebrew-bnq-local"
	ZIP_DIR="$(mktemp -d)"
	mkdir -p "$TAP_DIR/Casks/b"

	local app_src="$ZIP_DIR/BnqTestApp.app"
	mkdir -p "$app_src/Contents/MacOS"
	printf '#!/bin/sh\necho BnqTestApp\n' > "$app_src/Contents/MacOS/BnqTestApp"
	chmod +x "$app_src/Contents/MacOS/BnqTestApp"
	cat > "$app_src/Contents/Info.plist" <<- 'PLIST'
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
		"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0"><dict>
			<key>CFBundleName</key>
			<string>BnqTestApp</string>
			<key>CFBundleIdentifier</key>
			<string>com.bnqtest.app</string>
			<key>CFBundleShortVersionString</key>
			<string>1.0</string>
			<key>CFBundleVersion</key>
			<string>1</string>
		</dict></plist>
	PLIST

	(cd "$ZIP_DIR" && zip -qr "$ZIP_DIR/bnqtestapp-1.0.zip" BnqTestApp.app)
	local sha1; sha1=$(shasum -a 256 "$ZIP_DIR/bnqtestapp-1.0.zip" | awk '{print $1}')

	# v2: add a dummy file to change the sha
	cp -r "$app_src" "$ZIP_DIR/BnqTestApp_v2.app"
	echo "v2" > "$ZIP_DIR/BnqTestApp_v2.app/Contents/version.txt"
	mv "$ZIP_DIR/BnqTestApp_v2.app" "$ZIP_DIR/BnqTestApp.app"
	(cd "$ZIP_DIR" && zip -qr "$ZIP_DIR/bnqtestapp-2.0.zip" BnqTestApp.app)
	local sha2; sha2=$(shasum -a 256 "$ZIP_DIR/bnqtestapp-2.0.zip" | awk '{print $1}')

	# Restore v1 app for cask v1 install
	rm -rf "$ZIP_DIR/BnqTestApp.app"
	(cd "$ZIP_DIR" && unzip -q "$ZIP_DIR/bnqtestapp-1.0.zip")

	# Save sha2 for later
	printf '%s' "$sha2" > /tmp/bnq_test_sha2

	write_cask_v1 "$sha1"

	git -C "$TAP_DIR" init -q
	git -C "$TAP_DIR" add .
	git -C "$TAP_DIR" -c user.email="ci@test" -c user.name="CI" commit -qm "bnq-test-app 1.0"
	brew tap "$TEST_TAP" "$TAP_DIR" 2>/dev/null
}

write_cask_v1() {
	local sha1="$1"
	cat > "$TAP_DIR/Casks/b/bnq-test-app.rb" <<- CASK
		cask "bnq-test-app" do
			version "1.0"
			sha256 "$sha1"
			url "file://${ZIP_DIR}/bnqtestapp-1.0.zip"
			name "BnqTestApp"
			desc "Dummy cask for brew-no-quarantine integration tests"
			homepage "https://example.com"
			app "BnqTestApp.app"
		end
	CASK
}

update_tap_to_v2() {
	report info "Bumping local tap to v2.0 (so bnq-test-app becomes outdated) ..."
	local sha2; sha2=$(cat /tmp/bnq_test_sha2)
	cat > "$TAP_DIR/Casks/b/bnq-test-app.rb" <<- CASK
		cask "bnq-test-app" do
			version "2.0"
			sha256 "$sha2"
			url "file://${ZIP_DIR}/bnqtestapp-2.0.zip"
			name "BnqTestApp"
			desc "Dummy cask for brew-no-quarantine integration tests"
			homepage "https://example.com"
			app "BnqTestApp.app"
		end
	CASK
	git -C "$TAP_DIR" add .
	git -C "$TAP_DIR" -c user.email="ci@test" -c user.name="CI" commit -qm "bnq-test-app 2.0"
	brew update 2>/dev/null || true
}

revert_tap_to_v1() {
	report info "Reverting local tap to v1.0 ..."
	local sha1; sha1=$(shasum -a 256 "$ZIP_DIR/bnqtestapp-1.0.zip" | awk '{print $1}')
	write_cask_v1 "$sha1"
	git -C "$TAP_DIR" add .
	git -C "$TAP_DIR" -c user.email="ci@test" -c user.name="CI" commit -qm "revert bnq-test-app to 1.0"
	brew update 2>/dev/null || true
}

cleanup() {
	echo ""
	report info "Cleaning up ..."
	cleanup_test
	brew untap "$TEST_TAP" 2>/dev/null || true
	rm -f /tmp/bnq_test_sha2
	[[ -n "$TAP_DIR" ]] && rm -rf "$(dirname "$TAP_DIR")" 2>/dev/null || true
	[[ -n "$ZIP_DIR" ]] && rm -rf "$ZIP_DIR" 2>/dev/null || true
}

finish_test_script() {
	local rc=$?
	cleanup
	echo ""
	echo "======================================================"
	printf " Results for %s: " "$(basename "$0")"
	if [[ "$FAIL" -gt 0 ]]; then
		red "$FAIL failed"
		rc=1
	else
		green "$PASS passed"
	fi

	if [[ -n "${BNQ_STATE_FILE:-}" ]]; then
		echo "GROUP_NUM=$GROUP_NUM" > "$BNQ_STATE_FILE"
	fi

	exit "$rc"
}

init_test() {
	setup_local_tap
	trap finish_test_script EXIT
}

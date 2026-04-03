#!/bin/bash
# Emulator Test Helper Script
# Enables agents to build, install, run, screenshot, and interact with the game
# on MuMuPlayer Android emulator without Board intervention.
#
# Usage:
#   ./scripts/emulator_test.sh <command> [args...]
#
# Commands:
#   start        - Start the emulator (waits for Android to boot)
#   stop         - Stop the emulator
#   status       - Check emulator status
#   build        - Export debug APK via Godot headless
#   install      - Install the APK on the emulator
#   launch       - Launch the game app
#   screenshot   - Take a screenshot (saves to $TEMP/emu_screenshot.png)
#   tap <x> <y>  - Send a tap at coordinates
#   swipe <x1> <y1> <x2> <y2> [duration_ms] - Send a swipe gesture
#   text <string> - Type text
#   back         - Press back button
#   home         - Press home button
#   full-test    - Run full pipeline: start → build → install → launch → screenshot
#   logcat [filter] - Stream logcat (default: Godot:V *:S)

set -euo pipefail

MUMU_MGR="/c/Program Files/Netease/MuMuPlayer/nx_main/MuMuManager.exe"
GODOT="/c/Users/justf/Godot/Godot_v4.6-stable_win64_console.exe"
PROJECT_DIR="/c/Users/justf/OneDrive/바탕 화면/claude/joseon-deckbuilder"
APK_PATH="$PROJECT_DIR/build/android/Sijojeon.apk"
PACKAGE="com.sijojeon.deckbuilder"
VM_INDEX=0
ADB_TARGET="127.0.0.1:16384"
SCREENSHOT_PATH="${TEMP:-/tmp}/emu_screenshot.png"

cmd_start() {
    echo "Starting emulator..."
    MSYS_NO_PATHCONV=1 "$MUMU_MGR" control -v $VM_INDEX launch
    echo "Waiting for Android to boot..."
    for i in $(seq 1 30); do
        sleep 2
        local info
        info=$(MSYS_NO_PATHCONV=1 "$MUMU_MGR" info -v $VM_INDEX 2>/dev/null)
        if echo "$info" | grep -q '"is_android_started": true'; then
            echo "Emulator ready. Connecting ADB..."
            adb connect $ADB_TARGET 2>/dev/null || true
            echo "Done. ADB target: $ADB_TARGET"
            return 0
        fi
        echo "  ...waiting ($i/30)"
    done
    echo "ERROR: Emulator did not start within 60 seconds"
    return 1
}

cmd_stop() {
    echo "Stopping emulator..."
    MSYS_NO_PATHCONV=1 "$MUMU_MGR" control -v $VM_INDEX shutdown
    echo "Done."
}

cmd_status() {
    MSYS_NO_PATHCONV=1 "$MUMU_MGR" info -v $VM_INDEX 2>/dev/null
}

cmd_build() {
    echo "Building APK (Godot headless export)..."
    mkdir -p "$PROJECT_DIR/build/android"
    "$GODOT" --headless --export-debug "Android" "$APK_PATH" --path "$PROJECT_DIR" 2>&1
    echo "APK built: $APK_PATH"
    ls -lh "$APK_PATH"
}

cmd_install() {
    echo "Installing APK..."
    adb -s $ADB_TARGET install -r "$APK_PATH" 2>&1
    echo "Done."
}

cmd_launch() {
    echo "Launching $PACKAGE..."
    adb -s $ADB_TARGET shell monkey -p $PACKAGE -c android.intent.category.LAUNCHER 1 2>&1
    echo "App launched."
}

cmd_screenshot() {
    local output="${1:-$SCREENSHOT_PATH}"
    adb -s $ADB_TARGET exec-out screencap -p > "$output" 2>/dev/null
    local size
    size=$(wc -c < "$output")
    echo "Screenshot saved: $output ($size bytes)"
    echo "Use Claude Read tool to analyze the image."
}

cmd_tap() {
    local x=$1 y=$2
    adb -s $ADB_TARGET shell input tap "$x" "$y" 2>&1
    echo "Tapped at ($x, $y)"
}

cmd_swipe() {
    local x1=$1 y1=$2 x2=$3 y2=$4 duration=${5:-300}
    adb -s $ADB_TARGET shell input swipe "$x1" "$y1" "$x2" "$y2" "$duration" 2>&1
    echo "Swiped ($x1,$y1) -> ($x2,$y2) in ${duration}ms"
}

cmd_text() {
    local text=$1
    adb -s $ADB_TARGET shell input text "$text" 2>&1
    echo "Typed: $text"
}

cmd_back() {
    adb -s $ADB_TARGET shell input keyevent KEYCODE_BACK 2>&1
    echo "Back pressed"
}

cmd_home() {
    adb -s $ADB_TARGET shell input keyevent KEYCODE_HOME 2>&1
    echo "Home pressed"
}

cmd_logcat() {
    local filter="${1:-Godot:V *:S}"
    adb -s $ADB_TARGET logcat "$filter"
}

cmd_full_test() {
    echo "=== Full Test Pipeline ==="
    cmd_start
    echo ""
    cmd_build
    echo ""
    cmd_install
    echo ""
    sleep 2
    cmd_launch
    echo ""
    sleep 5
    cmd_screenshot
    echo ""
    echo "=== Pipeline Complete ==="
    echo "Screenshot at: $SCREENSHOT_PATH"
    echo "Analyze with: Read tool on the screenshot path"
}

# Main dispatch
case "${1:-help}" in
    start)      cmd_start ;;
    stop)       cmd_stop ;;
    status)     cmd_status ;;
    build)      cmd_build ;;
    install)    cmd_install ;;
    launch)     cmd_launch ;;
    screenshot) cmd_screenshot "${2:-}" ;;
    tap)        cmd_tap "$2" "$3" ;;
    swipe)      cmd_swipe "$2" "$3" "$4" "$5" "${6:-300}" ;;
    text)       cmd_text "$2" ;;
    back)       cmd_back ;;
    home)       cmd_home ;;
    logcat)     cmd_logcat "${2:-}" ;;
    full-test)  cmd_full_test ;;
    help|*)
        echo "Emulator Test Helper"
        echo ""
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  start              Start emulator and wait for boot"
        echo "  stop               Stop emulator"
        echo "  status             Check emulator status (JSON)"
        echo "  build              Export debug APK via Godot headless"
        echo "  install            Install APK on emulator"
        echo "  launch             Launch the game"
        echo "  screenshot [path]  Take screenshot (default: \$TEMP/emu_screenshot.png)"
        echo "  tap <x> <y>       Tap at coordinates (1080x1920 screen)"
        echo "  swipe <x1> <y1> <x2> <y2> [ms]  Swipe gesture"
        echo "  text <string>     Type text"
        echo "  back              Press back button"
        echo "  home              Press home button"
        echo "  logcat [filter]   Stream Godot logcat"
        echo "  full-test         Full pipeline: start→build→install→launch→screenshot"
        ;;
esac

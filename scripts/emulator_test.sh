#!/bin/bash
# 에뮬레이터 테스트 헬퍼 스크립트
# 여러 Android 에뮬레이터(MuMu, LDPlayer, BlueStacks)를 지원하며
# 빌드, 설치, 실행, 스크린샷, 터치 입력 테스트를 자동화합니다.
#
# 사용법:
#   ./scripts/emulator_test.sh <command> [args...]
#   EMU_TYPE=ldplayer ./scripts/emulator_test.sh start
#
# 에뮬레이터 선택 (EMU_TYPE 환경변수 또는 자동 감지):
#   mumu       - MuMu Player (HyperV 모드 비활성화 필수)
#   ldplayer   - LDPlayer (권장 - ADB 터치 호환성 우수)
#   bluestacks - BlueStacks 5
#   auto       - 설치된 에뮬레이터 자동 감지 (기본값)
#
# 명령어:
#   start        - 에뮬레이터 시작 (Android 부팅 대기)
#   stop         - 에뮬레이터 중지
#   status       - 에뮬레이터 상태 확인
#   build        - Godot headless로 디버그 APK 빌드
#   install      - 에뮬레이터에 APK 설치
#   launch       - 게임 앱 실행
#   screenshot   - 스크린샷 촬영 ($TEMP/emu_screenshot.png)
#   tap <x> <y>  - 좌표에 탭 전송
#   swipe <x1> <y1> <x2> <y2> [duration_ms] - 스와이프 제스처
#   text <string> - 텍스트 입력
#   back         - 뒤로가기 버튼
#   home         - 홈 버튼
#   touch-test   - ADB 터치 입력 호환성 테스트
#   full-test    - 전체 파이프라인: start → build → install → launch → screenshot
#   logcat [filter] - Godot logcat 스트림

set -euo pipefail

# === 에뮬레이터별 경로 설정 ===
MUMU_MGR="/c/Program Files/Netease/MuMuPlayer/nx_main/MuMuManager.exe"
LDPLAYER_DIR="/c/LDPlayer/LDPlayer9"
LDPLAYER_MGR="$LDPLAYER_DIR/ldconsole.exe"
BLUESTACKS_DIR="/c/Program Files/BlueStacks_nxt"
BLUESTACKS_MGR="$BLUESTACKS_DIR/HD-Player.exe"

GODOT="/c/Users/justf/Godot/Godot_v4.6-stable_win64_console.exe"
PROJECT_DIR="/c/Users/justf/OneDrive/바탕 화면/claude/joseon-deckbuilder"
APK_PATH="$PROJECT_DIR/build/android/Sijojeon.apk"
PACKAGE="com.sijojeon.deckbuilder"
VM_INDEX=0
SCREENSHOT_PATH="${TEMP:-/tmp}/emu_screenshot.png"

# === 에뮬레이터 자동 감지 ===
detect_emulator() {
    # 환경변수로 지정된 경우 우선 사용
    if [[ -n "${EMU_TYPE:-}" && "$EMU_TYPE" != "auto" ]]; then
        echo "$EMU_TYPE"
        return
    fi

    # LDPlayer 우선 (ADB 터치 호환성 최고)
    if [[ -f "$LDPLAYER_MGR" ]]; then
        echo "ldplayer"
        return
    fi

    # BlueStacks 차선
    if [[ -f "$BLUESTACKS_MGR" ]]; then
        echo "bluestacks"
        return
    fi

    # MuMu 마지막 (HyperV 문제 가능성)
    if [[ -f "$MUMU_MGR" ]]; then
        echo "mumu"
        return
    fi

    echo "none"
}

# === ADB 타겟 주소 결정 ===
get_adb_target() {
    local emu_type=$1
    case "$emu_type" in
        mumu)       echo "127.0.0.1:16384" ;;
        ldplayer)   echo "127.0.0.1:5555" ;;
        bluestacks) echo "127.0.0.1:5555" ;;
        *)          echo "127.0.0.1:5555" ;;
    esac
}

EMU_TYPE=$(detect_emulator)
ADB_TARGET=$(get_adb_target "$EMU_TYPE")

# === MuMu HyperV 감지 및 경고 ===
check_mumu_hyperv() {
    if [[ "$EMU_TYPE" != "mumu" ]]; then
        return 0
    fi

    local info
    info=$(MSYS_NO_PATHCONV=1 "$MUMU_MGR" info -v $VM_INDEX 2>/dev/null || echo "{}")

    # HyperV 모드 감지
    if echo "$info" | grep -qi "hyperv\|hyper-v"; then
        echo "========================================"
        echo "경고: MuMu Player가 HyperV 모드로 실행 중입니다!"
        echo ""
        echo "HyperV 모드에서는 ADB 터치 입력(input tap, input swipe,"
        echo "sendevent)이 Godot 앱에 전달되지 않습니다."
        echo ""
        echo "해결 방법:"
        echo "  1. MuMu 설정 > 기본 설정 > 렌더링 엔진을 '호환 모드'로 변경"
        echo "  2. 또는 LDPlayer로 전환: EMU_TYPE=ldplayer ./scripts/emulator_test.sh start"
        echo "  3. 또는 BlueStacks로 전환: EMU_TYPE=bluestacks ./scripts/emulator_test.sh start"
        echo "========================================"
        return 1
    fi

    # Windows HyperV 활성화 여부 확인
    if command -v systeminfo &>/dev/null; then
        if systeminfo 2>/dev/null | grep -qi "Hyper-V.*enabled\|하이퍼.*사용"; then
            echo "경고: Windows에 Hyper-V가 활성화되어 있습니다."
            echo "MuMu Player의 ADB 터치 호환성에 문제가 발생할 수 있습니다."
            echo "LDPlayer 또는 BlueStacks 사용을 권장합니다."
        fi
    fi
    return 0
}

# === 에뮬레이터 시작 ===
cmd_start() {
    echo "에뮬레이터 타입: $EMU_TYPE"

    if [[ "$EMU_TYPE" == "none" ]]; then
        echo "오류: 지원되는 에뮬레이터를 찾을 수 없습니다."
        echo "설치 경로를 확인하거나 EMU_TYPE 환경변수를 지정하세요."
        echo "지원: mumu, ldplayer, bluestacks"
        return 1
    fi

    case "$EMU_TYPE" in
        mumu)
            check_mumu_hyperv || echo "(HyperV 경고 — 터치 테스트가 실패할 수 있습니다)"
            echo "MuMu Player 시작 중..."
            MSYS_NO_PATHCONV=1 "$MUMU_MGR" control -v $VM_INDEX launch
            echo "Android 부팅 대기 중..."
            for i in $(seq 1 30); do
                sleep 2
                local info
                info=$(MSYS_NO_PATHCONV=1 "$MUMU_MGR" info -v $VM_INDEX 2>/dev/null)
                if echo "$info" | grep -q '"is_android_started": true'; then
                    echo "에뮬레이터 준비 완료. ADB 연결 중..."
                    adb connect "$ADB_TARGET" 2>/dev/null || true
                    echo "완료. ADB 타겟: $ADB_TARGET"
                    return 0
                fi
                echo "  ...대기 중 ($i/30)"
            done
            echo "오류: 60초 내에 에뮬레이터가 시작되지 않음"
            return 1
            ;;
        ldplayer)
            echo "LDPlayer 시작 중..."
            MSYS_NO_PATHCONV=1 "$LDPLAYER_MGR" launch --index $VM_INDEX 2>/dev/null
            echo "Android 부팅 대기 중..."
            for i in $(seq 1 30); do
                sleep 2
                if adb connect "$ADB_TARGET" 2>/dev/null | grep -q "connected"; then
                    echo "에뮬레이터 준비 완료. ADB 타겟: $ADB_TARGET"
                    return 0
                fi
                echo "  ...대기 중 ($i/30)"
            done
            echo "오류: 60초 내에 에뮬레이터가 시작되지 않음"
            return 1
            ;;
        bluestacks)
            echo "BlueStacks 시작 중..."
            MSYS_NO_PATHCONV=1 "$BLUESTACKS_MGR" &
            echo "Android 부팅 대기 중..."
            for i in $(seq 1 30); do
                sleep 2
                if adb connect "$ADB_TARGET" 2>/dev/null | grep -q "connected"; then
                    echo "에뮬레이터 준비 완료. ADB 타겟: $ADB_TARGET"
                    return 0
                fi
                echo "  ...대기 중 ($i/30)"
            done
            echo "오류: 60초 내에 에뮬레이터가 시작되지 않음"
            return 1
            ;;
    esac
}

# === 에뮬레이터 중지 ===
cmd_stop() {
    echo "에뮬레이터 중지 중 ($EMU_TYPE)..."
    case "$EMU_TYPE" in
        mumu)
            MSYS_NO_PATHCONV=1 "$MUMU_MGR" control -v $VM_INDEX shutdown
            ;;
        ldplayer)
            MSYS_NO_PATHCONV=1 "$LDPLAYER_MGR" quit --index $VM_INDEX 2>/dev/null
            ;;
        bluestacks)
            # BlueStacks는 프로세스 종료로 중지
            taskkill //IM "HD-Player.exe" //F 2>/dev/null || true
            ;;
    esac
    echo "완료."
}

# === 에뮬레이터 상태 확인 ===
cmd_status() {
    echo "에뮬레이터 타입: $EMU_TYPE"
    echo "ADB 타겟: $ADB_TARGET"
    echo ""

    case "$EMU_TYPE" in
        mumu)
            echo "=== MuMu 정보 ==="
            MSYS_NO_PATHCONV=1 "$MUMU_MGR" info -v $VM_INDEX 2>/dev/null
            ;;
        ldplayer)
            echo "=== LDPlayer 정보 ==="
            MSYS_NO_PATHCONV=1 "$LDPLAYER_MGR" list2 2>/dev/null || echo "(정보 조회 불가)"
            ;;
        bluestacks)
            echo "=== BlueStacks 정보 ==="
            tasklist 2>/dev/null | grep -i "HD-Player" || echo "(실행 중이 아님)"
            ;;
        none)
            echo "에뮬레이터를 찾을 수 없습니다."
            return 1
            ;;
    esac

    echo ""
    echo "=== ADB 연결 상태 ==="
    adb devices 2>/dev/null || echo "ADB를 찾을 수 없습니다."
}

cmd_build() {
    echo "APK 빌드 중 (Godot headless export)..."
    mkdir -p "$PROJECT_DIR/build/android"
    "$GODOT" --headless --export-debug "Android" "$APK_PATH" --path "$PROJECT_DIR" 2>&1
    echo "APK 빌드 완료: $APK_PATH"
    ls -lh "$APK_PATH"
}

cmd_install() {
    echo "APK 설치 중..."
    adb -s "$ADB_TARGET" install -r "$APK_PATH" 2>&1
    echo "완료."
}

cmd_launch() {
    echo "$PACKAGE 실행 중..."
    adb -s "$ADB_TARGET" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 2>&1
    echo "앱 실행됨."
}

cmd_screenshot() {
    local output="${1:-$SCREENSHOT_PATH}"
    adb -s "$ADB_TARGET" exec-out screencap -p > "$output" 2>/dev/null
    local size
    size=$(wc -c < "$output")
    echo "스크린샷 저장: $output ($size bytes)"
    echo "Claude Read 도구로 이미지 분석 가능."
}

cmd_tap() {
    local x=$1 y=$2
    adb -s "$ADB_TARGET" shell input tap "$x" "$y" 2>&1
    echo "탭: ($x, $y)"
}

cmd_swipe() {
    local x1=$1 y1=$2 x2=$3 y2=$4 duration=${5:-300}
    adb -s "$ADB_TARGET" shell input swipe "$x1" "$y1" "$x2" "$y2" "$duration" 2>&1
    echo "스와이프: ($x1,$y1) -> ($x2,$y2) ${duration}ms"
}

cmd_text() {
    local text=$1
    adb -s "$ADB_TARGET" shell input text "$text" 2>&1
    echo "입력: $text"
}

cmd_back() {
    adb -s "$ADB_TARGET" shell input keyevent KEYCODE_BACK 2>&1
    echo "뒤로가기"
}

cmd_home() {
    adb -s "$ADB_TARGET" shell input keyevent KEYCODE_HOME 2>&1
    echo "홈 버튼"
}

cmd_logcat() {
    local filter="${1:-Godot:V *:S}"
    adb -s "$ADB_TARGET" logcat "$filter"
}

# === ADB 터치 입력 호환성 테스트 ===
cmd_touch_test() {
    echo "=== ADB 터치 입력 호환성 테스트 ==="
    echo "에뮬레이터: $EMU_TYPE"
    echo "ADB 타겟: $ADB_TARGET"
    echo ""

    # ADB 연결 확인
    echo "[1/5] ADB 연결 확인..."
    if ! adb -s "$ADB_TARGET" shell echo "ok" 2>/dev/null | grep -q "ok"; then
        echo "실패: ADB 연결 불가. 에뮬레이터가 실행 중인지 확인하세요."
        return 1
    fi
    echo "  통과"

    # input tap 테스트
    echo "[2/5] input tap 테스트..."
    if adb -s "$ADB_TARGET" shell input tap 540 960 2>&1 | grep -qi "error\|exception\|denied"; then
        echo "  실패: input tap이 차단됨"
        local tap_ok=false
    else
        echo "  통과"
        local tap_ok=true
    fi

    # input swipe 테스트
    echo "[3/5] input swipe 테스트..."
    if adb -s "$ADB_TARGET" shell input swipe 540 960 540 460 300 2>&1 | grep -qi "error\|exception\|denied"; then
        echo "  실패: input swipe이 차단됨"
        local swipe_ok=false
    else
        echo "  통과"
        local swipe_ok=true
    fi

    # getevent 접근 테스트 (터치 디바이스 확인)
    echo "[4/5] 터치 입력 디바이스 확인..."
    local touch_devs
    touch_devs=$(adb -s "$ADB_TARGET" shell getevent -pl 2>/dev/null | grep -c "ABS_MT_POSITION" || echo "0")
    if [[ "$touch_devs" -gt 0 ]]; then
        echo "  통과: 멀티터치 디바이스 감지됨"
    else
        echo "  경고: 멀티터치 디바이스를 감지할 수 없음"
    fi

    # Godot 앱 터치 전달 테스트 (앱이 실행 중인 경우)
    echo "[5/5] Godot 앱 포그라운드 확인..."
    local foreground
    foreground=$(adb -s "$ADB_TARGET" shell dumpsys activity activities 2>/dev/null | grep -o "$PACKAGE[^ ]*" | head -1 || echo "")
    if [[ -n "$foreground" ]]; then
        echo "  Godot 앱 실행 중: $foreground"
        echo "  터치 전송 테스트 (화면 중앙 탭)..."
        adb -s "$ADB_TARGET" shell input tap 540 960 2>/dev/null
        sleep 1
        echo "  터치가 전달되었는지 logcat에서 확인하세요:"
        echo "    ./scripts/emulator_test.sh logcat"
    else
        echo "  Godot 앱이 실행 중이 아님 (터치 전달 테스트 건너뜀)"
    fi

    echo ""
    echo "=== 테스트 결과 요약 ==="
    echo "에뮬레이터: $EMU_TYPE"
    echo "ADB 연결: 통과"
    echo "input tap: $( [[ "$tap_ok" == "true" ]] && echo "통과" || echo "실패" )"
    echo "input swipe: $( [[ "$swipe_ok" == "true" ]] && echo "통과" || echo "실패" )"

    if [[ "$tap_ok" != "true" || "$swipe_ok" != "true" ]]; then
        echo ""
        echo "터치 입력에 문제가 있습니다."
        if [[ "$EMU_TYPE" == "mumu" ]]; then
            echo "MuMu HyperV 모드가 원인일 수 있습니다."
            echo "EMU_TYPE=ldplayer로 전환하거나 MuMu 설정에서 HyperV를 비활성화하세요."
        fi
        return 1
    fi
    echo ""
    echo "모든 터치 입력 테스트 통과!"
    return 0
}

# === 전체 파이프라인 테스트 ===
cmd_full_test() {
    echo "=== 전체 테스트 파이프라인 ==="
    echo "에뮬레이터: $EMU_TYPE"
    echo ""
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
    echo "--- 터치 호환성 테스트 ---"
    cmd_touch_test
    echo ""
    echo "=== 파이프라인 완료 ==="
    echo "스크린샷: $SCREENSHOT_PATH"
    echo "Claude Read 도구로 이미지 분석 가능."
}

# === 메인 디스패치 ===
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
    touch-test) cmd_touch_test ;;
    full-test)  cmd_full_test ;;
    help|*)
        echo "에뮬레이터 테스트 헬퍼"
        echo ""
        echo "사용법: $0 <command> [args...]"
        echo "환경변수: EMU_TYPE=mumu|ldplayer|bluestacks|auto (기본: auto)"
        echo "현재 감지된 에뮬레이터: $EMU_TYPE (ADB: $ADB_TARGET)"
        echo ""
        echo "명령어:"
        echo "  start              에뮬레이터 시작 및 부팅 대기"
        echo "  stop               에뮬레이터 중지"
        echo "  status             에뮬레이터 상태 확인"
        echo "  build              Godot headless로 디버그 APK 빌드"
        echo "  install            에뮬레이터에 APK 설치"
        echo "  launch             게임 실행"
        echo "  screenshot [path]  스크린샷 촬영 (기본: \$TEMP/emu_screenshot.png)"
        echo "  tap <x> <y>       좌표에 탭 (1080x1920 화면)"
        echo "  swipe <x1> <y1> <x2> <y2> [ms]  스와이프 제스처"
        echo "  text <string>     텍스트 입력"
        echo "  back              뒤로가기 버튼"
        echo "  home              홈 버튼"
        echo "  logcat [filter]   Godot logcat 스트림"
        echo "  touch-test        ADB 터치 입력 호환성 테스트"
        echo "  full-test         전체 파이프라인: start→build→install→launch→screenshot→touch-test"
        ;;
esac

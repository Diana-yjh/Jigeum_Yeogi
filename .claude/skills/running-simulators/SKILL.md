---
name: running-simulators
description: Use when iOS 시뮬레이터나 Android 에뮬레이터에서 이 앱을 실행/재실행해야 할 때, flutter run을 백그라운드로 띄우거나 exit 144·setsid 오류·MissingPluginException을 만났을 때
---

# 시뮬레이터/에뮬레이터 실행

이 저장소에서 검증된 실행 루프. `flutter run`을 detach로 띄우고 로그 감시로 성공을 확인한다.

## iOS 시뮬레이터 (검증된 UDID: iPhone 시뮬레이터)

```bash
pkill -f "flutter run -d 2B4CAE2C" 2>/dev/null; sleep 2
rm -f /tmp/claude-flutter-run.log
nohup flutter run -d 2B4CAE2C-D09D-4CB7-AEBC-A9D03A3F5043 \
  > /tmp/claude-flutter-run.log 2>&1 < /dev/null & disown
until grep -qE "Flutter run key commands|Error|Exception|failed" /tmp/claude-flutter-run.log 2>/dev/null; do sleep 2; done
grep -m2 -E "Flutter run key commands|Error|Exception|failed" /tmp/claude-flutter-run.log
```

- 감시 루프는 `run_in_background`로 돌린다. `Flutter run key commands` = 성공.
- 다른 UDID가 필요하면 `xcrun simctl list devices | grep Booted`.

## Android 에뮬레이터 (AVD: jy_pixel)

```bash
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
nohup "$HOME/Library/Android/sdk/emulator/emulator" -avd jy_pixel \
  > /tmp/claude-android-emu.log 2>&1 < /dev/null & disown
adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 3; done
nohup flutter run -d emulator-5554 > /tmp/claude-flutter-android.log 2>&1 < /dev/null & disown
# 이후 iOS와 같은 grep 감시 루프
```

## 주의 (이 Mac에서 실제로 겪은 것)

| 증상 | 원인/해결 |
|------|-----------|
| `zsh: command not found: setsid` | macOS에 setsid 없음 — `nohup … & disown` 사용 |
| 백그라운드 태스크가 exit 144로 "실패" | 새 실행을 위해 이전 `flutter run`을 pkill한 정상 교체 — 무시 |
| `MissingPluginException` | 새 네이티브 플러그인은 hot reload로 안 붙는다 — 전체 재빌드(재실행) |
| 코드 수정 반영 | detach 실행이라 hot reload를 보낼 수 없다 — pkill 후 재실행으로 반영 |

수정 → 반영 사이클: `flutter analyze`·`flutter test` 통과 확인 → 위 재실행 블록.

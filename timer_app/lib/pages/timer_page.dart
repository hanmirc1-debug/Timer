import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'shared_design.dart';

import 'package:vibration/vibration.dart';

class TimerAppPage extends StatefulWidget {
  final ValueChanged<bool> onRunningChanged;
  final GlobalKey clockKey;
  const TimerAppPage({
    super.key,
    required this.onRunningChanged,
    required this.clockKey,
  });

  @override
  State<TimerAppPage> createState() => _TimerAppPageState();
}

class _TimerAppPageState extends State<TimerAppPage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  Timer? _vibrationTimer;
  double targetSeconds = globalTimerMaxSeconds.value;
  double currentSeconds = globalTimerMaxSeconds.value;
  bool isRunning = false;
  bool isAlarmPlaying = false;
  bool alarmTriggered = false;
  bool hasStarted = false;
  bool isCompleted = false; // 🔥 추가

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this)
      ..addListener(() {
        setState(() {
          currentSeconds = controller.value * targetSeconds;
        });
      });

    controller.addStatusListener((status) {
      debugPrint("STATUS: $status");
      if (status == AnimationStatus.dismissed &&
          !alarmTriggered &&
          hasStarted) {
        controller.stop(); // 🔥 추가 (무한 트리거 방지)
        debugPrint("🔥 DISMISSED");

        alarmTriggered = true;
        _triggerAlarm();
        _checkAutoPomodoro();
      }
    });

    // 글로벌 리스너 연결
    globalTimerMaxSeconds.addListener(_onMaxScaleChanged);

    // 🌟 [추가됨] 뽀모도로 관련 리스너 등록 (켜짐/꺼짐 및 시간 변경 감지)
    globalPomodoroMode.addListener(_onPomodoroModeChanged);
    globalPomodoroWorkTime.addListener(_onPomodoroSettingsChanged);
    globalPomodoroShortBreak.addListener(_onPomodoroSettingsChanged);
    globalPomodoroLongBreak.addListener(_onPomodoroSettingsChanged);

    // 🌟 페이지 렌더링 시 이미 뽀모도로가 켜져 있다면 시간 즉시 동기화
    if (globalPomodoroMode.value && !isRunning) {
      _syncPomodoroTime();
    }
  }

  @override
  void dispose() {
    globalTimerMaxSeconds.removeListener(_onMaxScaleChanged);
    globalPomodoroMode.removeListener(_onPomodoroModeChanged);
    globalPomodoroWorkTime.removeListener(_onPomodoroSettingsChanged);
    globalPomodoroShortBreak.removeListener(_onPomodoroSettingsChanged);
    globalPomodoroLongBreak.removeListener(_onPomodoroSettingsChanged);
    controller.dispose();
    super.dispose();
  }

  // =========================================================
  // 🌟 [추가됨] 뽀모도로 상태 동기화 함수들
  // =========================================================
  void _onPomodoroModeChanged() {
    if (globalPomodoroMode.value && !isRunning) {
      _syncPomodoroTime();
    }
    setState(() {}); // 뽀모도로 ON/OFF에 따른 UI(드래그 잠금 등) 갱신
  }

  void _onPomodoroSettingsChanged() {
    if (globalPomodoroMode.value && !isRunning) {
      _syncPomodoroTime();
    }
  }

  void _syncPomodoroTime() {
    // 현재 뽀모도로 상태(집중/휴식)에 맞는 텍스트 값을 가져와서 초 단위로 변환
    if (globalPomodoroState.value == PomodoroState.work) {
      double min =
          double.tryParse(
            globalPomodoroWorkTime.value.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          25;
      _applyManualTime(min * 60);
    } else if (globalPomodoroState.value == PomodoroState.shortBreak) {
      double min =
          double.tryParse(
            globalPomodoroShortBreak.value.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          5;
      _applyManualTime(min * 60);
    } else {
      double min =
          double.tryParse(
            globalPomodoroLongBreak.value.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          15;
      _applyManualTime(min * 60);
    }
  }

  // 🌟 [추가됨] 뽀모도로 모드일 때 자체적으로 가장 알맞은 최대 눈금을 계산
  double _getPomodoroMaxScale(double targetSec) {
    if (targetSec <= 60) return 60.0; // 1분 이하 -> 눈금 60초
    if (targetSec <= 120) return 120.0; // 2분 이하 -> 눈금 120초
    if (targetSec <= 3600) return 3600.0; // 60분 이하 -> 눈금 60분
    return 7200.0; // 그 외 -> 눈금 120분
  }

  void _onMaxScaleChanged() {
    // 🌟 [수정됨] 뽀모도로 모드가 아닐 때만 기존의 글로벌 눈금 변경 적용
    if (!isRunning && !globalPomodoroMode.value) {
      setState(() {
        if (targetSeconds > globalTimerMaxSeconds.value) {
          targetSeconds = globalTimerMaxSeconds.value;
        }
        currentSeconds = targetSeconds;
        controller.value = 1.0;
      });
    }
  }

  void _startVibrationLoop() {
    _vibrationTimer?.cancel();

    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!isAlarmPlaying) {
        _vibrationTimer?.cancel();
        return;
      }

      Vibration.vibrate(duration: 400, amplitude: 255);
    });
  }

  void _triggerAlarm() async {
    debugPrint("triggerAlarm called");
    if (!globalAlarmEnabled.value) return;
    if (isAlarmPlaying) return;

    isAlarmPlaying = true;

    isCompleted = true; // 🔥 추가

    controller.stop(); // 🔥 꼭 넣어

    await GlobalBgmManager.stopBgm();

    final option = globalAlarmSound.value;

    if (option == "진동만") {
      _startVibrationLoop();
      return;
    }

    await GlobalBgmManager.playAlarmSound(option);

    _startVibrationLoop(); // 🔥 추가
  }

  void _checkAutoPomodoro() async {
    if (!globalPomodoroMode.value) return;

    bool isGoingToBreak = (globalPomodoroState.value == PomodoroState.work);
    bool isAuto = isGoingToBreak
        ? globalPomodoroAutoBreak.value
        : globalPomodoroAutoWork.value;

    if (isAuto) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || !isAlarmPlaying) return;

      GlobalBgmManager.stopAllSound();
      _vibrationTimer?.cancel();
      setState(() {
        isAlarmPlaying = false;
        isRunning = false;
        widget.onRunningChanged(false);
      });

      _handlePomodoroNextStep();
    }
  }

  void _handlePomodoroNextStep() {
    if (!globalPomodoroMode.value) return;

    if (globalPomodoroState.value == PomodoroState.work) {
      // 집중 -> 휴식 셋팅 (기존과 동일)
      globalCompletedCycles.value++;

      int cycleTarget =
          int.tryParse(
            globalPomodoroCycleCount.value.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          4;

      if (globalCompletedCycles.value > 0 &&
          globalCompletedCycles.value % cycleTarget == 0) {
        globalPomodoroState.value = PomodoroState.longBreak;
        double min =
            double.tryParse(
              globalPomodoroLongBreak.value.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            15;
        _applyManualTime(min * 60);
      } else {
        globalPomodoroState.value = PomodoroState.shortBreak;
        double min =
            double.tryParse(
              globalPomodoroShortBreak.value.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            5;
        _applyManualTime(min * 60);
      }

      if (globalPomodoroAutoBreak.value) start();
    } else {
      // 🌟 [수정됨] 휴식 -> 집중 셋팅으로 넘어갈 때 최대 세션 검사!

      // 방금 끝난 휴식이 '긴 휴식'이라면, 목표한 최대 세션에 도달했는지 확인합니다.
      if (globalPomodoroState.value == PomodoroState.longBreak) {
        String maxSessionStr = globalPomodoroMaxSessions.value;

        if (!maxSessionStr.contains("제한 없음")) {
          int maxSessions =
              int.tryParse(maxSessionStr.replaceAll(RegExp(r'[^0-9]'), '')) ??
              1;
          int cycleTarget =
              int.tryParse(
                globalPomodoroCycleCount.value.replaceAll(
                  RegExp(r'[^0-9]'),
                  '',
                ),
              ) ??
              4;

          // 완료한 총 횟수가 (최대 세션 * 1세션당 횟수)에 도달했다면? (예: 1세션 * 4번 = 4)
          if (globalCompletedCycles.value >= (maxSessions * cycleTarget)) {
            // 🍅 모든 뽀모도로 일정이 끝났습니다! 완전히 초기화하고 멈춥니다.
            globalPomodoroState.value = PomodoroState.work;
            globalCompletedCycles.value = 0; // 횟수 리셋

            // 시계를 다시 '집중 모드' 초기 시간으로 되돌려 놓습니다.
            double min =
                double.tryParse(
                  globalPomodoroWorkTime.value.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  ),
                ) ??
                25;
            _applyManualTime(min * 60);

            // 🚨 중요: 여기서 return 해버려서 밑에 있는 start()가 실행되지 않게 막습니다.
            debugPrint("🍅 설정한 최대 뽀모도로 세션이 모두 종료되었습니다.");
            return;
          }
        }
      }

      // 최대 횟수에 도달하지 않았다면, 정상적으로 다음 집중 모드를 셋팅하고 시작합니다.
      globalPomodoroState.value = PomodoroState.work;
      double min =
          double.tryParse(
            globalPomodoroWorkTime.value.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          25;
      _applyManualTime(min * 60);

      if (globalPomodoroAutoWork.value) start();
    }
  }

  void start() {
    debugPrint("start called with targetSeconds: $targetSeconds");
    if (targetSeconds <= 0) return;

    hasStarted = true;
    alarmTriggered = false;
    isAlarmPlaying = false;

    controller.duration = Duration(seconds: targetSeconds.toInt());
    if (isCompleted) {
      // 🔥 완료 상태면 초기화 후 시작
      controller.value = 1.0;
      isCompleted = false;
    }
    // 아니면 이어서 시작 (controller.value 유지)
    if (controller.value == 0) {
      controller.value = 1.0; // 🔥 0이면 강제 리셋
    }

    controller.reverse(from: controller.value);

    setState(() => isRunning = true);
    widget.onRunningChanged(true);

    if (globalBgmEnabled.value) {
      GlobalBgmManager.playBgm(globalBgmTrack.value);
    }
  }

  void stop() {
    debugPrint("stop called");
    controller.stop();
    setState(() => isRunning = false);
    widget.onRunningChanged(false);

    GlobalBgmManager.stopBgm();
  }

  void updateStartTime(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    double angle = atan2(dy, dx);
    double clockwiseFromTop = angle - (-pi / 2);
    if (clockwiseFromTop < 0) clockwiseFromTop += 2 * pi;

    double maxScale = globalTimerMaxSeconds.value;
    double draggedSeconds = (clockwiseFromTop / (2 * pi)) * maxScale;

    setState(() {
      targetSeconds = maxScale - draggedSeconds;
      if (targetSeconds <= 0 || targetSeconds >= maxScale) {
        targetSeconds = maxScale;
      }
      currentSeconds = targetSeconds;
      controller.duration = Duration(seconds: targetSeconds.toInt());
      controller.value = 1.0;
    });
  }

  void _showTimeInputDialog() {
    if (isRunning) return;

    TextEditingController minController = TextEditingController(
      text: (targetSeconds ~/ 60).toString(),
    );
    TextEditingController secController = TextEditingController(
      text: (targetSeconds % 60).toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            int m = int.tryParse(minController.text) ?? 0;
            int s = int.tryParse(secController.text) ?? 0;
            double totalInputSeconds = (m * 60 + s).toDouble();

            bool isExceeding = totalInputSeconds > 7200;
            Color textColor = isExceeding ? Colors.red : Colors.black87;

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "시간 직접 입력",
                style: TextStyle(
                  color: globalClockColor.value,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            labelText: "분 (Min)",
                            labelStyle: TextStyle(color: textColor),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isExceeding ? Colors.red : Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isExceeding
                                    ? Colors.red
                                    : globalClockColor.value,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (val) => setStateDialog(() {}),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          ":",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: secController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            labelText: "초 (Sec)",
                            labelStyle: TextStyle(color: textColor),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isExceeding ? Colors.red : Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isExceeding
                                    ? Colors.red
                                    : globalClockColor.value,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (val) => setStateDialog(() {}),
                        ),
                      ),
                    ],
                  ),
                  if (isExceeding)
                    const Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: Text(
                        "120분 이하로 설정해주세요.",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "취소",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExceeding
                        ? Colors.grey.shade400
                        : globalClockColor.value,
                  ),
                  onPressed: isExceeding
                      ? null
                      : () {
                          if (totalInputSeconds > 0)
                            _applyManualTime(totalInputSeconds);
                          Navigator.pop(context);
                        },
                  child: const Text(
                    "적용",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _applyManualTime(double inputSec) {
    setState(() {
      // 🌟 [수정됨] 뽀모도로 모드가 아닐 때만 글로벌 최대 눈금 문구를 변경합니다.
      if (!globalPomodoroMode.value) {
        if (inputSec <= 60)
          globalTimerMaxString.value = "60초 (1분)";
        else if (inputSec <= 120)
          globalTimerMaxString.value = "120초 (2분)";
        else if (inputSec <= 3600)
          globalTimerMaxString.value = "60분";
        else
          globalTimerMaxString.value = "120분";
      }

      targetSeconds = inputSec;
      currentSeconds = targetSeconds;
      controller.duration = Duration(seconds: targetSeconds.toInt());
      controller.value = 1.0;
    });
  }

  void toggle() {
    if (isRunning) {
      stop();
    } else {
      if (isCompleted) {
        controller.value = 1.0;
        currentSeconds = targetSeconds;
        isCompleted = false;
      }

      start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BaseClockLayout(
          key: widget.clockKey,
          isRunning: isRunning,
          onTapToggle: toggle,
          // 🌟 뽀모도로 모드일 때는 드래그(수동 조작) 잠금
          onPanUpdate: (!isRunning && !globalPomodoroMode.value)
              ? updateStartTime
              : null,
          drawnSeconds: currentSeconds,
          // 🌟 뽀모도로 모드일 때는 뽀모도로 자체 눈금을, 아닐 때는 전역 눈금을 따름
          maxScaleSeconds: globalPomodoroMode.value
              ? _getPomodoroMaxScale(targetSeconds)
              : globalTimerMaxSeconds.value,
          isTimer: true,
          digitalSeconds: currentSeconds,
          // 🌟 뽀모도로 모드일 때는 길게 눌러 수동 입력하는 기능도 잠금
          onDigitalLongPress: globalPomodoroMode.value
              ? null
              : () => _showTimeInputDialog(),
        ),
        // =========================================================
        // 🌟 상단 뽀모도로 배지 표시 UI (설정 변경 시 즉시 업데이트 버전)
        // =========================================================
        Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: globalPomodoroMode,
            builder: (context, isPomodoro, child) {
              if (!isPomodoro) return const SizedBox.shrink();

              // 1. 상태(집중/휴식) 감시
              return ValueListenableBuilder<PomodoroState>(
                valueListenable: globalPomodoroState,
                builder: (context, state, child) {
                  // 2. 색상 감시
                  return ValueListenableBuilder<Color>(
                    valueListenable: globalClockColor,
                    builder: (context, clockColor, child) {
                      // 3. 완료 횟수 감시
                      return ValueListenableBuilder<int>(
                        valueListenable: globalCompletedCycles,
                        builder: (context, cycles, child) {
                          // 4. 🔥 긴 휴식 주기 설정값 감시 (추가됨!)
                          return ValueListenableBuilder<String>(
                            valueListenable: globalPomodoroCycleCount,
                            builder: (context, cycleSetting, child) {
                              // 5. 🔥 최대 세션 설정값 감시 (추가됨!)
                              return ValueListenableBuilder<String>(
                                valueListenable: globalPomodoroMaxSessions,
                                builder: (context, sessionSetting, child) {
                                  String statusText =
                                      (state == PomodoroState.work)
                                      ? "집중 모드"
                                      : (state == PomodoroState.shortBreak
                                            ? "짧은 휴식"
                                            : "긴 휴식");
                                  IconData icon = (state == PomodoroState.work)
                                      ? Icons.local_fire_department
                                      : (state == PomodoroState.shortBreak
                                            ? Icons.coffee
                                            : Icons.hotel);

                                  // 설정값 파싱
                                  int cycleTarget =
                                      int.tryParse(
                                        cycleSetting.replaceAll(
                                          RegExp(r'[^0-9]'),
                                          '',
                                        ),
                                      ) ??
                                      4;

                                  // 현재 사이클 및 세션 계산
                                  int displayCycle =
                                      (state == PomodoroState.work)
                                      ? (cycles % cycleTarget) + 1
                                      : (cycles > 0
                                            ? ((cycles - 1) % cycleTarget) + 1
                                            : 1);

                                  int displaySession =
                                      (state == PomodoroState.work)
                                      ? (cycles ~/ cycleTarget) + 1
                                      : (cycles > 0
                                            ? ((cycles - 1) ~/ cycleTarget) + 1
                                            : 1);

                                  String totalSessions =
                                      sessionSetting.contains("제한 없음")
                                      ? "제한 없음"
                                      : sessionSetting.replaceAll(
                                          RegExp(r'[^0-9]'),
                                          '',
                                        );

                                  return Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                icon,
                                                size: 16,
                                                color: clockColor,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "뽀모도로 - $statusText ($displayCycle/$cycleTarget)",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: clockColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "세션 (현재/최대) : $displaySession / $totalSessions",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: clockColor.withOpacity(
                                                0.7,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),

        // 🔥 알람일 때 화면 덮기 (유저 터치 감지)
        if (isAlarmPlaying)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                GlobalBgmManager.stopAllSound();

                _vibrationTimer?.cancel(); // 🔥 추가

                setState(() {
                  isAlarmPlaying = false;
                  isRunning = false;
                  widget.onRunningChanged(false);
                });

                if (globalPomodoroMode.value) {
                  _handlePomodoroNextStep();
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    );
  }
}

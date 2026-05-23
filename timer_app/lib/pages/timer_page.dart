import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'shared_design.dart';

import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'tutorial_overlay.dart'; // 방금 만든 파일 임포트!

class TimerAppPage extends StatefulWidget {
  final ValueChanged<bool> onRunningChanged;
  final GlobalKey clockKey;
  const TimerAppPage({
    super.key,
    required this.onRunningChanged,
    required this.clockKey,
  });

  @override
  State<TimerAppPage> createState() => TimerAppPageState(); // 🔥 상태를 외부에서 접근할 수 있도록 퍼블릭으로 변경
}

class TimerAppPageState extends State<TimerAppPage>
    with TickerProviderStateMixin {
  // 🔥 TickerProviderStateMixin으로 변경 (애니메이션 컨트롤러 2개 사용)
  late AnimationController controller;
  late AnimationController _dragAnimController; // 🔥 튜토리얼 50초 드래그 시뮬레이션용 애니메이터

  Timer? _vibrationTimer;
  double targetSeconds = globalTimerMaxSeconds.value;
  double currentSeconds = globalTimerMaxSeconds.value;
  bool isRunning = false;
  bool isAlarmPlaying = false;
  bool alarmTriggered = false;
  bool hasStarted = false;
  bool isCompleted = false;
  // 👇==== 새로 추가할 변수들 ====👇
  double _savedResetSeconds = 60.0; // 🎯 리셋을 위해 시작 시점의 시간을 저장할 변수
  double _dragStartY = 0.0; // 스와이프 시작 Y 좌표
  DateTime? _dragStartTime; // 스와이프 시작 시간
  bool _wasRunningWhenDragStarted = false; // 🎯 스와이프 시작 시점의 타이머 상태를 기억
  // 👆========================👆

  // 🔥 튜토리얼 전용 변수들
  int _tutorialStep = 0; // 0이면 튜토리얼 아님
  Map<String, dynamic> _savedSettings = {}; // 기존 유저 설정 임시 저장용

  @override
  void initState() {
    super.initState();

    // 1. 기존 타이머 애니메이션
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
        controller.stop();
        debugPrint("🔥 DISMISSED");

        alarmTriggered = true;
        _triggerAlarm();
        _checkAutoPomodoro();
      }
    });

    // 2. 튜토리얼 드래그 50초 애니메이션 컨트롤러
    _dragAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 글로벌 리스너 연결
    globalTimerMaxSeconds.addListener(_onMaxScaleChanged);
    globalPomodoroMode.addListener(_onPomodoroModeChanged);
    globalPomodoroWorkTime.addListener(_onPomodoroSettingsChanged);
    globalPomodoroShortBreak.addListener(_onPomodoroSettingsChanged);
    globalPomodoroLongBreak.addListener(_onPomodoroSettingsChanged);

    if (globalPomodoroMode.value && !isRunning) {
      _syncPomodoroTime();
    }

    // 🔥 처음 접속한 유저인지 확인하고 튜토리얼 시작
    _checkFirstTimeTutorial();
  }

  @override
  void dispose() {
    globalTimerMaxSeconds.removeListener(_onMaxScaleChanged);
    globalPomodoroMode.removeListener(_onPomodoroModeChanged);
    globalPomodoroWorkTime.removeListener(_onPomodoroSettingsChanged);
    globalPomodoroShortBreak.removeListener(_onPomodoroSettingsChanged);
    globalPomodoroLongBreak.removeListener(_onPomodoroSettingsChanged);
    controller.dispose();
    _dragAnimController.dispose();
    super.dispose();
  }

  // =========================================================
  // 🌟 [추가됨] 튜토리얼 로직
  // =========================================================
  void _checkFirstTimeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeen = prefs.getBool('has_seen_tutorial') ?? false;
    if (!hasSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        startTutorial();
      });
    }
  }

  // 🔥 설정창에서 "다시 보기"를 눌렀을 때 호출할 수 있는 퍼블릭 함수
  void startTutorial() {
    globalIsTutorialActive.value = true; // 🔥 추가: 튜토리얼 시작 알림
    // 1. 현재 사용자의 개인 설정을 임시로 저장해둡니다.
    _savedSettings = {
      'bg': globalBgColor.value,
      'clock': globalClockColor.value,
      'digital': globalDigitalColor.value,
      'indicator': globalIndicatorColor.value,
      'bgVideo': globalBgVideoName.value,
      'clockVideo': globalClockVideoName.value,
      'maxString': globalTimerMaxString.value,
      'maxSec': globalTimerMaxSeconds.value,
      'displayMode': globalDisplayMode.value,
      'indicatorMode': globalIndicatorMode.value,
    };

    // 2. 튜토리얼용 디폴트 테마로 강제 변신! (벽돌색 테마 & 60초)
    globalBgColor.value = const Color(0xFF252528);
    globalClockColor.value = const Color.fromARGB(255, 185, 70, 70);
    globalDigitalColor.value = const Color(0xFFE5E5EA);
    globalIndicatorColor.value = const Color(0xFF8E8E93);
    globalBgVideoName.value = "사용 안 함";
    globalClockVideoName.value = "사용 안 함";
    globalTimerMaxString.value = "60초 (1분)";
    globalTimerMaxSeconds.value = 60.0;
    globalDisplayMode.value = "BOTH";
    globalIndicatorMode.value = "NUMBER";

    // 타이머 0초로 초기화 후 튜토리얼 1단계 시작
    stop();
    setState(() {
      targetSeconds = 60.0;
      currentSeconds = 60.0;
      // 🔥 [핵심 추가] duration도 60초에 맞게 세팅해 주어야 화면에 빨간색이 1.0(꽉 참) 비율로 제대로 그려집니다
      controller.duration = const Duration(seconds: 60);
      controller.value = 1.0;
      _tutorialStep = 1;
    });
  }

  void _nextTutorialStep() {
    if (_tutorialStep == 1) {
      // 🔥 수정: 60초(꽉 참)에서 50초(10초만큼 비워짐)로 가는 애니메이션
      // begin: 1.0 (꽉 찬 상태) -> end: 50/60 (50초 지점까지 비워짐)
      Animation<double> anim = Tween<double>(begin: 60.0, end: 50.0).animate(
        CurvedAnimation(parent: _dragAnimController, curve: Curves.easeInOut),
      );

      anim.addListener(() {
        setState(() {
          targetSeconds = anim.value; // 숫자는 60 -> 50으로 줄어듦
          currentSeconds = targetSeconds;

          // 타이머 눈금 상에서 50초 위치를 가리키도록 설정
          controller.duration = Duration(
            milliseconds: (targetSeconds * 1000).toInt(),
          );
          controller.value = 1.0; // reverse 모드이므로 1.0이면 해당 시간만큼 색이 칠해진 상태
        });
      });
      _dragAnimController.forward(from: 0.0);

      setState(() {
        _tutorialStep = 2; // "이런 식으로 맞춰집니다" 말풍선으로 변경
      });
      return;
    }
    // case 4
    if (_tutorialStep == 3) {
      // 🔥 수정: 60초(꽉 참)에서 50초(10초만큼 비워짐)로 가는 애니메이션
      Animation<double> anim = Tween<double>(begin: 50.0, end: 0).animate(
        CurvedAnimation(parent: _dragAnimController, curve: Curves.easeInOut),
      );

      anim.addListener(() {
        setState(() {
          targetSeconds = anim.value;
          currentSeconds = targetSeconds;

          // 타이머 눈금 상에서 50초 위치를 가리키도록 설정
          controller.duration = Duration(
            milliseconds: (targetSeconds * 1000).toInt(),
          );
          controller.value = 1.0; // reverse 모드이므로 1.0이면 해당 시간만큼 색이 칠해진 상태
        });
      });
      _dragAnimController.forward(from: 0.0);

      setState(() {
        _tutorialStep = 4; // "이런 식으로 맞춰집니다" 말풍선으로 변경
      });
      return;
    }
    // case 5
    if (_tutorialStep == 4) {
      // 🔥 수정: 60초(꽉 참)에서 50초(10초만큼 비워짐)로 가는 애니메이션
      Animation<double> anim = Tween<double>(begin: 0, end: 50.0).animate(
        CurvedAnimation(parent: _dragAnimController, curve: Curves.easeInOut),
      );

      anim.addListener(() {
        setState(() {
          targetSeconds = anim.value;
          currentSeconds = targetSeconds;

          // 타이머 눈금 상에서 50초 위치를 가리키도록 설정
          controller.duration = Duration(
            milliseconds: (targetSeconds * 1000).toInt(),
          );
          controller.value = 1.0; // reverse 모드이므로 1.0이면 해당 시간만큼 색이 칠해진 상태
        });
      });
      _dragAnimController.forward(from: 0.0);

      setState(() {
        _tutorialStep = 5; // "이런 식으로 맞춰집니다" 말풍선으로 변경
      });
      return;
    }

    if (_tutorialStep == 9) {
      _showTutorialFinishDialog();
      return;
    }

    setState(() {
      _tutorialStep++;
    });
  }

  void _endTutorial() async {
    globalIsTutorialActive.value = false; // 🔥 추가: 튜토리얼 종료 알림
    // 튜토리얼이 끝나면 저장해뒀던 유저의 원래 테마와 설정을 완벽히 복구합니다.
    globalBgColor.value = _savedSettings['bg'];
    globalClockColor.value = _savedSettings['clock'];
    globalDigitalColor.value = _savedSettings['digital'];
    globalIndicatorColor.value = _savedSettings['indicator'];
    globalBgVideoName.value = _savedSettings['bgVideo'];
    globalClockVideoName.value = _savedSettings['clockVideo'];
    globalTimerMaxString.value = _savedSettings['maxString'];
    globalTimerMaxSeconds.value = _savedSettings['maxSec'];
    globalDisplayMode.value = _savedSettings['displayMode'];
    globalIndicatorMode.value = _savedSettings['indicatorMode'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', true);

    setState(() {
      _tutorialStep = 0;
      // 시간 원래대로 초기화
      targetSeconds = globalTimerMaxSeconds.value;
      currentSeconds = targetSeconds;
      controller.value = 1.0;
    });
  }

  void _showTutorialFinishDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("앱 사용 준비 완료!"),
        content: const Text(
          "이제 나만의 타이머를 자유롭게 써보세요!\n\n(튜토리얼은 '설정 > 고객 센터'에서 언제든 다시 볼 수 있습니다.)",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("한 번 더 보기"),
            onPressed: () {
              Navigator.pop(context);
              startTutorial(); // 튜토리얼 처음부터 다시 시작
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("타이머 시작하기"),
            onPressed: () {
              Navigator.pop(context);
              _endTutorial(); // 튜토리얼 종료 및 복구
            },
          ),
        ],
      ),
    );
  }
  // =========================================================

  void _onPomodoroModeChanged() {
    if (globalPomodoroMode.value && !isRunning) {
      _syncPomodoroTime();
    }
    setState(() {});
  }

  void _onPomodoroSettingsChanged() {
    if (globalPomodoroMode.value && !isRunning) {
      _syncPomodoroTime();
    }
  }

  void _syncPomodoroTime() {
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

  double _getPomodoroMaxScale(double targetSec) {
    if (targetSec <= 60) return 60.0;
    if (targetSec <= 120) return 120.0;
    if (targetSec <= 3600) return 3600.0;
    return 7200.0;
  }

  void _onMaxScaleChanged() {
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

    if (!globalVibrationEnabled.value) return;

    // 끝나자마자 바로 1회 진동
    Vibration.vibrate(duration: 400, amplitude: 255);

    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!isAlarmPlaying || !globalVibrationEnabled.value) {
        _vibrationTimer?.cancel();
        return;
      }

      Vibration.vibrate(duration: 400, amplitude: 255);
    });
  }

  void _triggerAlarm() async {
    debugPrint("triggerAlarm called");

    if (isAlarmPlaying) return;

    final bool soundEnabled = globalAlarmEnabled.value;
    final bool vibrationEnabled = globalVibrationEnabled.value;

    debugPrint(
      "alarm option => soundEnabled: $soundEnabled, vibrationEnabled: $vibrationEnabled",
    );

    // 알림음 OFF + 진동 OFF면 아무것도 안 함
    if (!soundEnabled && !vibrationEnabled) {
      isCompleted = true;
      controller.stop();
      return;
    }

    isAlarmPlaying = true;
    isCompleted = true;
    controller.stop();

    await GlobalBgmManager.stopBgm();

    // 알림음 ON일 때만 소리 재생
    if (soundEnabled) {
      await GlobalBgmManager.playAlarmSound(globalAlarmSound.value);
    }

    // 진동 ON일 때만 진동 반복
    if (vibrationEnabled) {
      _startVibrationLoop();
    }
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

          if (globalCompletedCycles.value >= (maxSessions * cycleTarget)) {
            globalPomodoroState.value = PomodoroState.work;
            globalCompletedCycles.value = 0;

            double min =
                double.tryParse(
                  globalPomodoroWorkTime.value.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  ),
                ) ??
                25;
            _applyManualTime(min * 60);

            debugPrint("🍅 설정한 최대 뽀모도로 세션이 모두 종료되었습니다.");
            return;
          }
        }
      }

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

    // 👇==== 새로 추가: 시작할 때의 시간을 기억해둠! ====👇
    _savedResetSeconds = targetSeconds;
    // 👆==========================================👆

    hasStarted = true;
    alarmTriggered = false;
    isAlarmPlaying = false;

    controller.duration = Duration(
      milliseconds: (targetSeconds * 1000).toInt(),
    );
    if (isCompleted) {
      controller.value = 1.0;
      isCompleted = false;
    }
    if (controller.value == 0) {
      controller.value = 1.0;
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

    _vibrationTimer?.cancel();
    Vibration.cancel();

    setState(() => isRunning = false);
    widget.onRunningChanged(false);

    GlobalBgmManager.stopBgm();
  }

  void updateStartTime(Offset localPosition, Size size) {
    if (_tutorialStep > 0) return; // 🔥 튜토리얼 중에는 드래그 방지

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
      controller.duration = Duration(
        milliseconds: (targetSeconds * 1000).toInt(),
      );
      controller.value = 1.0;
    });
  }

  void _showTimeInputDialog() {
    if (isRunning || _tutorialStep > 0) return;

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
      controller.duration = Duration(
        milliseconds: (targetSeconds * 1000).toInt(),
      );
      controller.value = 1.0;
    });
  }

  DateTime? _lastToggleTime;
  void toggle() {
    if (_tutorialStep > 0) return; // 🔥 튜토리얼 중에는 터치 작동 방지

    final now = DateTime.now();
    if (_lastToggleTime != null &&
        now.difference(_lastToggleTime!).inMilliseconds < 300) {
      debugPrint("고스트 터치 방어 완료!");
      return;
    }
    _lastToggleTime = now;

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

  // // 👇==== 정확히 이 위치에 붙여넣으세요! (toggle 함수 끝나는 곳과 build 함수 시작하는 곳 사이) ====👇
  //   // 🔄 타이머 초기화 (리셋) 함수 (아래로 스와이프 시 실행됨)
  //   void _resetTimer() {
  //     // 튜토리얼 중이거나 타이머가 이미 실행중일 때는 리셋되지 않음
  //     // (만약 잠금 기능 상태 변수가 따로 있다면 '|| isLocked' 를 여기에 추가해주세요)
  //     if (isRunning || _tutorialStep > 0) return;

  //     setState(() {
  //       // 드래그해서 맞춰둔 목표 시간(예: 50초)으로 되돌림
  //       currentSeconds = targetSeconds;
  //       // 애니메이션 재생 시간도 50초에 맞춰서 다시 세팅
  //       controller.duration = Duration(milliseconds: (targetSeconds * 1000).toInt());
  //       // 타이머 원형 색상을 다시 꽉 찬 상태(1.0)로 되돌림
  //       controller.value = 1.0;
  //       isCompleted = false;
  //     });
  //   }
  //   // 👆===================================================================👆
  // 🔄 타이머 초기화 (리셋) 함수
  void _resetTimer() {
    if (_tutorialStep > 0) return;

    setState(() {
      // 🎯 방금 스와이프 하느라 시계가 건드려져서 시간이 꼬였어도,
      // 시작할 때 저장해둔 시간으로 완벽 복원!
      targetSeconds = _savedResetSeconds;
      currentSeconds = targetSeconds;
      controller.duration = Duration(
        milliseconds: (targetSeconds * 1000).toInt(),
      );
      controller.value = 1.0;
      isCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        // 🎯 1. 화면에 손이 닿는 순간의 위치, 시간, 그리고 '현재 타이머가 돌아가고 있는지'를 기억합니다!
        _dragStartY = event.position.dy;
        _dragStartTime = DateTime.now();
        _wasRunningWhenDragStarted = isRunning;
      },
      onPointerUp: (event) {
        if (_dragStartTime == null || _tutorialStep > 0) return;

        // 🎯 2. 스와이프를 시작할 때 타이머가 돌아가고 있었다면, 무조건 스와이프(리셋)를 무시합니다!
        // (스와이프 도중에 main.dart 때문에 타이머가 꺼져버렸더라도 상관없이 차단됨)
        if (_wasRunningWhenDragStarted) {
          debugPrint("동작 중 스와이프 시도: 차단 완료!");
          return;
        }

        final dy = event.position.dy - _dragStartY;
        final dt = DateTime.now().difference(_dragStartTime!).inMilliseconds;

        // y축으로 50픽셀 이상, 0.5초(500ms) 이내로 빠르게 내린 경우 = 아래로 스와이프!
        if (dy > 50 && dt > 0 && dt < 500) {
          final velocity = dy / (dt / 1000); // 픽셀/초 단위 속도 계산

          // [마우스 환경 대응] 크롬 테스트를 위해 속도 기준을 100으로 낮춤
          if (velocity > 100) {
            debugPrint("fff! 완벽하게 스와이프 인식됨");

            // 🎯 3. 빠른 스와이프 때문에 정지 상태에서 타이머가 실수로 켜졌다면, 다시 끄고 리셋 진행
            if (isRunning) {
              stop();
            }

            _resetTimer();
          }
        }
      },
      child: Stack(
        children: [
          BaseClockLayout(
            key: widget.clockKey,
            isRunning: isRunning,
            onTapToggle: toggle,
            onPanUpdate: (!isRunning && !globalPomodoroMode.value)
                ? updateStartTime
                : null,
            drawnSeconds: currentSeconds,
            maxScaleSeconds: globalPomodoroMode.value
                ? _getPomodoroMaxScale(targetSeconds)
                : globalTimerMaxSeconds.value,
            isTimer: true,
            digitalSeconds: currentSeconds,
            onDigitalLongPress: globalPomodoroMode.value
                ? null
                : () => _showTimeInputDialog(),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: globalPomodoroMode,
              builder: (context, isPomodoro, child) {
                if (!isPomodoro) return const SizedBox.shrink();

                return ValueListenableBuilder<PomodoroState>(
                  valueListenable: globalPomodoroState,
                  builder: (context, state, child) {
                    return ValueListenableBuilder<Color>(
                      valueListenable: globalClockColor,
                      builder: (context, clockColor, child) {
                        return ValueListenableBuilder<int>(
                          valueListenable: globalCompletedCycles,
                          builder: (context, cycles, child) {
                            return ValueListenableBuilder<String>(
                              valueListenable: globalPomodoroCycleCount,
                              builder: (context, cycleSetting, child) {
                                return ValueListenableBuilder<String>(
                                  valueListenable: globalPomodoroMaxSessions,
                                  builder: (context, sessionSetting, child) {
                                    String statusText =
                                        (state == PomodoroState.work)
                                        ? "집중 모드"
                                        : (state == PomodoroState.shortBreak
                                              ? "짧은 휴식"
                                              : "긴 휴식");
                                    IconData icon =
                                        (state == PomodoroState.work)
                                        ? Icons.local_fire_department
                                        : (state == PomodoroState.shortBreak
                                              ? Icons.coffee
                                              : Icons.hotel);

                                    int cycleTarget =
                                        int.tryParse(
                                          cycleSetting.replaceAll(
                                            RegExp(r'[^0-9]'),
                                            '',
                                          ),
                                        ) ??
                                        4;
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
                                              ? ((cycles - 1) ~/ cycleTarget) +
                                                    1
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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

          if (isAlarmPlaying)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  GlobalBgmManager.stopAllSound();
                  _vibrationTimer?.cancel();
                  Vibration.cancel();

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

          // 🔥 [튜토리얼용 오버레이 위치] 화면 전체를 덮어씌웁니다.
          if (_tutorialStep > 0)
            Positioned.fill(
              child: TutorialOverlayWidget(
                step: _tutorialStep,
                onTap: _nextTutorialStep,
              ),
            ),
        ],
      ),
    );
  }
}

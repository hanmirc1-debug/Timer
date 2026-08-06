import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'shared_design.dart';

import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'tutorial_overlay.dart';
import 'package:flutter/foundation.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';

class TimerAppPage extends StatefulWidget {
  final ValueChanged<bool> onRunningChanged;
  final GlobalKey clockKey;
  const TimerAppPage({
    super.key,
    required this.onRunningChanged,
    required this.clockKey,
  });

  @override
  State<TimerAppPage> createState() => TimerAppPageState();
}

class _EffectiveAlertState {
  final bool sound;
  final bool vibration;

  const _EffectiveAlertState({required this.sound, required this.vibration});
}

class TimerAppPageState extends State<TimerAppPage>
    with TickerProviderStateMixin {
  late AnimationController controller;
  late AnimationController _dragAnimController;

  Timer? _vibrationTimer;
  double targetSeconds = globalTimerMaxSeconds.value;
  double currentSeconds = globalTimerMaxSeconds.value;
  bool isRunning = false;
  bool isAlarmPlaying = false;
  bool alarmTriggered = false;
  bool hasStarted = false;
  bool isCompleted = false;
  double _savedResetSeconds = 60.0;
  double _dragStartY = 0.0;
  DateTime? _dragStartTime;
  bool _wasRunningWhenDragStarted = false;

  int _tutorialStep = 0;
  Map<String, dynamic> _savedSettings = {};

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

        alarmTriggered = true;
        _triggerAlarm();
        _checkAutoPomodoro();
      }
    });

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

  void _checkFirstTimeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeen = prefs.getBool('has_seen_tutorial') ?? false;
    if (!hasSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        startTutorial();
      });
    }
  }

  void startTutorial() {
    globalIsTutorialActive.value = true;
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

    stop();
    setState(() {
      targetSeconds = 60.0;
      currentSeconds = 60.0;
      controller.duration = const Duration(seconds: 60);
      controller.value = 1.0;
      _tutorialStep = 1;
    });
  }

  void _nextTutorialStep() {
    if (_tutorialStep == 1) {
      Animation<double> anim = Tween<double>(begin: 60.0, end: 50.0).animate(
        CurvedAnimation(parent: _dragAnimController, curve: Curves.easeInOut),
      );

      anim.addListener(() {
        setState(() {
          targetSeconds = anim.value;
          currentSeconds = targetSeconds;

          controller.duration = Duration(
            milliseconds: (targetSeconds * 1000).toInt(),
          );
          controller.value = 1.0;
        });
      });
      _dragAnimController.forward(from: 0.0);

      setState(() {
        _tutorialStep = 2;
      });
      return;
    }
    if (_tutorialStep == 3) {
      Animation<double> anim = Tween<double>(begin: 50.0, end: 0).animate(
        CurvedAnimation(parent: _dragAnimController, curve: Curves.easeInOut),
      );

      anim.addListener(() {
        setState(() {
          targetSeconds = anim.value;
          currentSeconds = targetSeconds;

          controller.duration = Duration(
            milliseconds: (targetSeconds * 1000).toInt(),
          );
          controller.value = 1.0;
        });
      });
      _dragAnimController.forward(from: 0.0);

      setState(() {
        _tutorialStep = 4;
      });
      return;
    }
    if (_tutorialStep == 4) {
      Animation<double> anim = Tween<double>(begin: 0, end: 50.0).animate(
        CurvedAnimation(parent: _dragAnimController, curve: Curves.easeInOut),
      );

      anim.addListener(() {
        setState(() {
          targetSeconds = anim.value;
          currentSeconds = targetSeconds;

          controller.duration = Duration(
            milliseconds: (targetSeconds * 1000).toInt(),
          );
          controller.value = 1.0;
        });
      });
      _dragAnimController.forward(from: 0.0);

      setState(() {
        _tutorialStep = 5;
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
    globalIsTutorialActive.value = false;
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
              startTutorial();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("타이머 시작하기"),
            onPressed: () {
              Navigator.pop(context);
              _endTutorial();
            },
          ),
        ],
      ),
    );
  }

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

  Future<_EffectiveAlertState> _getEffectiveAlertState() async {
    final bool appSoundEnabled = globalAlarmEnabled.value;
    final bool appVibrationEnabled = globalVibrationEnabled.value;

    if (kIsWeb) {
      return _EffectiveAlertState(
        sound: appSoundEnabled,
        vibration: appVibrationEnabled,
      );
    }

    try {
      final RingerModeStatus ringerStatus = await SoundMode.ringerModeStatus;

      if (ringerStatus == RingerModeStatus.silent) {
        return const _EffectiveAlertState(sound: false, vibration: false);
      }

      if (ringerStatus == RingerModeStatus.vibrate) {
        return _EffectiveAlertState(
          sound: false,
          vibration: appVibrationEnabled,
        );
      }

      if (ringerStatus == RingerModeStatus.normal) {
        return _EffectiveAlertState(
          sound: appSoundEnabled,
          vibration: appVibrationEnabled,
        );
      }
    } catch (e) {
      debugPrint("폰 소리 모드 확인 실패: $e");
    }

    return _EffectiveAlertState(
      sound: appSoundEnabled,
      vibration: appVibrationEnabled,
    );
  }

  void _startVibrationLoop({required bool allowVibration}) {
    _vibrationTimer?.cancel();

    if (!allowVibration) return;

    Vibration.vibrate(duration: 400, amplitude: 255);

    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!isAlarmPlaying || !allowVibration || !globalVibrationEnabled.value) {
        _vibrationTimer?.cancel();
        Vibration.cancel();
        return;
      }

      Vibration.vibrate(duration: 400, amplitude: 255);
    });
  }

  void _triggerAlarm() async {
    if (isAlarmPlaying) return;

    final effectiveAlert = await _getEffectiveAlertState();

    if (!effectiveAlert.sound && !effectiveAlert.vibration) {
      isCompleted = true;
      controller.stop();

      setState(() {
        isRunning = false;
      });

      widget.onRunningChanged(false);
      return;
    }

    isAlarmPlaying = true;
    isCompleted = true;
    controller.stop();

    setState(() {
      isRunning = false;
    });

    widget.onRunningChanged(false);

    await GlobalBgmManager.stopBgm();

    if (effectiveAlert.sound) {
      await GlobalBgmManager.playAlarmSound(globalAlarmSound.value);
    }

    if (effectiveAlert.vibration) {
      _startVibrationLoop(allowVibration: true);
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
      Vibration.cancel();
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
    if (targetSeconds <= 0) return;

    _savedResetSeconds = targetSeconds;

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
    controller.stop();

    _vibrationTimer?.cancel();
    Vibration.cancel();

    setState(() => isRunning = false);
    widget.onRunningChanged(false);

    GlobalBgmManager.stopBgm();
  }

  void updateStartTime(Offset localPosition, Size size) {
    if (_tutorialStep > 0) return;

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
    if (_tutorialStep > 0) return;

    final now = DateTime.now();
    if (_lastToggleTime != null &&
        now.difference(_lastToggleTime!).inMilliseconds < 300) {
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

  void _resetTimer() {
    if (_tutorialStep > 0) return;

    setState(() {
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
        _dragStartY = event.position.dy;
        _dragStartTime = DateTime.now();
        _wasRunningWhenDragStarted = isRunning;
      },
      onPointerUp: (event) {
        final startTime = _dragStartTime;
        if (startTime == null || _tutorialStep > 0) return;

        if (_wasRunningWhenDragStarted) {
          return;
        }

        final dy = event.position.dy - _dragStartY;
        final dt = DateTime.now().difference(startTime).inMilliseconds;

        if (dy > 50 && dt > 0 && dt < 500) {
          final velocity = dy / (dt / 1000);
          if (velocity > 100) {

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

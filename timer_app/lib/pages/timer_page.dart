import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'shared_design.dart';

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

  double targetSeconds = globalTimerMaxSeconds.value;
  double currentSeconds = globalTimerMaxSeconds.value;
  bool isRunning = false;
  bool isAlarmPlaying = false;
  bool alarmTriggered = false;
  bool hasStarted = false; // 🔥 추가
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

      if (status == AnimationStatus.dismissed && !alarmTriggered) {
        debugPrint("🔥 DISMISSED");

        alarmTriggered = true;
        _triggerAlarm();
      }
    });
    globalTimerMaxSeconds.addListener(_onMaxScaleChanged);
  }

  void _onMaxScaleChanged() {
    if (!isRunning) {
      setState(() {
        if (targetSeconds > globalTimerMaxSeconds.value) {
          targetSeconds = globalTimerMaxSeconds.value;
        }
        currentSeconds = targetSeconds;
        controller.value = 1.0;
      });
    }
  }

  void _triggerAlarm() async {
    debugPrint("triggerAlarm called");
    if (!globalAlarmEnabled.value) return;
    if (isAlarmPlaying) return;

    isAlarmPlaying = true;

    await GlobalBgmManager.stopBgm();

    final option = globalAlarmSound.value;

    if (option == "진동만") {
      HapticFeedback.vibrate();
      return;
    }

    await GlobalBgmManager.playAlarmSound(option);
  }

  void start() {
    debugPrint("start called with targetSeconds: $targetSeconds");
    if (targetSeconds <= 0) return;

    alarmTriggered = false;
    isAlarmPlaying = false;

    controller.reset();
    controller.duration = Duration(seconds: targetSeconds.toInt());
    controller.reverse(from: 1.0);

    setState(() => isRunning = true);
    widget.onRunningChanged(true);

    // 🔥 BGM 시작
    if (globalBgmEnabled.value) {
      GlobalBgmManager.playBgm(globalBgmTrack.value); // 🔥 이거 추가
    }
  }

  void stop() {
    debugPrint("stop called");
    controller.stop();
    setState(() => isRunning = false);
    widget.onRunningChanged(false);

    GlobalBgmManager.stopBgm(); // 🔥 BGM만 끔
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

  // =========================================================
  // 🌟 [수정됨] 120분 제한 및 실시간 유효성 검사가 적용된 다이얼로그!
  // =========================================================
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
        // 💡 StatefulBuilder를 써서 창 안에서 사용자가 글자를 칠 때마다 즉시 새로고침 되게 합니다.
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            int m = int.tryParse(minController.text) ?? 0;
            int s = int.tryParse(secController.text) ?? 0;
            double totalInputSeconds = (m * 60 + s).toDouble();

            // 🔥 120분(7200초)을 초과했는지 체크!
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
                            // 🔥 에러 상태에 따라 테두리 색상도 변경
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
                          onChanged: (val) =>
                              setStateDialog(() {}), // 글자 칠 때마다 즉시 검사
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
                  // 🔥 에러 메시지 띄우기
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
                  // 🔥 120분 넘으면 버튼을 회색으로 만들고 비활성화(null) 시킵니다!
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExceeding
                        ? Colors.grey.shade400
                        : globalClockColor.value,
                  ),
                  onPressed: isExceeding
                      ? null
                      : () {
                          if (totalInputSeconds > 0) {
                            _applyManualTime(totalInputSeconds);
                          }
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

  // 💡 [기능 2-1] 자동 스케일 업(Scale-up) 로직
  void _applyManualTime(double inputSec) {
    setState(() {
      // 입력된 시간에 맞춰 가장 적절한 눈금 단계로 알아서 조절해줍니다.
      if (inputSec <= 60)
        globalTimerMaxString.value = "60초 (1분)";
      else if (inputSec <= 120)
        globalTimerMaxString.value = "120초 (2분)";
      else if (inputSec <= 3600)
        globalTimerMaxString.value = "60분";
      else
        globalTimerMaxString.value = "120분"; // 120분을 넘진 못하게 막아둠

      targetSeconds = inputSec;
      currentSeconds = targetSeconds;
      controller.duration = Duration(seconds: targetSeconds.toInt());
      controller.value = 1.0;
    });
  }

  @override
  void dispose() {
    globalTimerMaxSeconds.removeListener(_onMaxScaleChanged);
    controller.dispose();
    super.dispose();
  }

  void toggle() {
    isRunning ? stop() : start();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BaseClockLayout(
          key: widget.clockKey,
          isRunning: isRunning,
          onTapToggle: () {},
          onPanUpdate: !isRunning ? updateStartTime : null,
          drawnSeconds: currentSeconds,
          maxScaleSeconds: globalTimerMaxSeconds.value,
          isTimer: true,
          digitalSeconds: currentSeconds,
          onDigitalLongPress: () => _showTimeInputDialog(),
        ),

        // 🔥 알람일 때만 덮기
        if (isAlarmPlaying)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque, // 🔥 다시 opaque로
              onTap: () {
                GlobalBgmManager.stopAllSound();

                setState(() {
                  isAlarmPlaying = false;
                });
              },
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    );
  }
}

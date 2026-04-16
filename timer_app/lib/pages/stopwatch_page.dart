import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'dart:math';
import 'shared_design.dart';

class StopwatchPage extends StatefulWidget {
  final ValueChanged<bool> onRunningChanged;
  final GlobalKey clockKey; 
  const StopwatchPage({
    super.key,
    required this.onRunningChanged,
    required this.clockKey,
  });

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  
  // 💡 초깃값을 60 대신 전역 설정값(globalTimerMaxSeconds)으로 동기화!
  double targetMaxSeconds = globalTimerMaxSeconds.value;
  double _draggedSeconds = 0;
  double currentSeconds = 0;

  bool isDragging = false;
  bool isRunning = false;
  bool hasStarted = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: targetMaxSeconds.toInt()),
    )..addListener(() {
        setState(() => currentSeconds = controller.value * targetMaxSeconds);
      });
      
    // 전역 스케일이 바뀌면 반영되도록 리스너 등록
    globalTimerMaxSeconds.addListener(_onGlobalMaxChanged);
  }

  void _onGlobalMaxChanged() {
    if (!hasStarted && !isDragging) {
      setState(() {
        targetMaxSeconds = globalTimerMaxSeconds.value;
        _draggedSeconds = 0;
      });
    }
  }

  void start() {
    if (targetMaxSeconds <= 0) return;
    controller.duration = Duration(seconds: targetMaxSeconds.toInt());

    if (controller.value == 0.0) {
      controller.reset();
    }

    controller.forward();

    setState(() {
      isRunning = true;
      hasStarted = true;
    });

    widget.onRunningChanged(true);
  }

  void stop() {
    controller.stop();
    setState(() => isRunning = false);
    widget.onRunningChanged(false);
  }

  void updateTargetTime(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    double angle = atan2(dx, -dy);
    if (angle < 0) angle += 2 * pi;

    double maxScale = globalTimerMaxSeconds.value;
    setState(() {
      _draggedSeconds = (angle / (2 * pi)) * maxScale;
      if (_draggedSeconds == 0) _draggedSeconds = maxScale;
    });
  }

  // =========================================================
  // 🌟 [추가됨] 스탑워치용 시간 직접 입력 (120분 제한, 자동 스케일 업)
  // =========================================================
  void _showTimeInputDialog() {
    if (isRunning) return; 

    TextEditingController minController = TextEditingController(text: (targetMaxSeconds ~/ 60).toString());
    TextEditingController secController = TextEditingController(text: (targetMaxSeconds % 60).toInt().toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            int m = int.tryParse(minController.text) ?? 0;
            int s = int.tryParse(secController.text) ?? 0;
            double totalInputSeconds = (m * 60 + s).toDouble();
            
            bool isExceeding = totalInputSeconds > 7200; // 120분 넘으면 true
            Color textColor = isExceeding ? Colors.red : Colors.black87;

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("스탑워치 목표 설정", style: TextStyle(color: globalClockColor.value, fontWeight: FontWeight.bold)),
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
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                          decoration: InputDecoration(
                            labelText: "분 (Min)", labelStyle: TextStyle(color: textColor),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isExceeding ? Colors.red : Colors.grey)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isExceeding ? Colors.red : globalClockColor.value, width: 2)),
                          ),
                          onChanged: (val) => setStateDialog(() {}),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(":", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor))),
                      Expanded(
                        child: TextField(
                          controller: secController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                          decoration: InputDecoration(
                            labelText: "초 (Sec)", labelStyle: TextStyle(color: textColor),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isExceeding ? Colors.red : Colors.grey)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isExceeding ? Colors.red : globalClockColor.value, width: 2)),
                          ),
                          onChanged: (val) => setStateDialog(() {}),
                        ),
                      ),
                    ],
                  ),
                  if (isExceeding)
                    const Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: Text("120분 이하로 설정해주세요.", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: isExceeding ? Colors.grey.shade400 : globalClockColor.value),
                  onPressed: isExceeding ? null : () {
                    if (totalInputSeconds > 0) {
                      _applyManualTime(totalInputSeconds); 
                    }
                    Navigator.pop(context); 
                  },
                  child: const Text("적용", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _applyManualTime(double inputSec) {
    setState(() {
      // 🔥 [수정됨] 무조건 입력한 시간에 가장 알맞게 꽉 끼는 스케일로 스마트하게 변경!
      if (inputSec <= 30) globalTimerMaxString.value = "30초";
      else if (inputSec <= 60) globalTimerMaxString.value = "60초 (1분)";
      else if (inputSec <= 120) globalTimerMaxString.value = "120초 (2분)";
      else if (inputSec <= 1800) globalTimerMaxString.value = "30분";
      else if (inputSec <= 3600) globalTimerMaxString.value = "60분";
      else globalTimerMaxString.value = "120분"; 

      targetMaxSeconds = inputSec;
      currentSeconds = 0;
      hasStarted = false; // 새로운 목표를 세웠으니 대기 상태
      controller.reset();
    });
  }

  @override
  void dispose() {
    globalTimerMaxSeconds.removeListener(_onGlobalMaxChanged);
    controller.dispose();
    super.dispose();
  }

  void toggle() {
    isRunning ? stop() : start();
  }

  @override
  Widget build(BuildContext context) {
    double displayMaxScale;
    double displayDrawnSeconds = 0;
    double displayDigitalSeconds = 0;
    
    // 💡 기준값을 항상 전역 설정에서 가져옴
    double maxScaleFromSettings = globalTimerMaxSeconds.value;

    if (isDragging) {
      displayMaxScale = maxScaleFromSettings; 
    } else if (!hasStarted) {
      displayMaxScale = maxScaleFromSettings;
    } else {
      displayMaxScale = targetMaxSeconds;
    }

    if (isDragging) {
      displayDrawnSeconds = _draggedSeconds;
      displayDigitalSeconds = _draggedSeconds;
    } else if (!hasStarted) {
      displayDrawnSeconds = targetMaxSeconds;
      displayDigitalSeconds = targetMaxSeconds;
    } else {
      displayDrawnSeconds = currentSeconds;
      displayDigitalSeconds = currentSeconds;
    }

    return BaseClockLayout(
      key: widget.clockKey, 
      isRunning: isRunning,
      onTapToggle: () {},
      
      onPanStart: (!isRunning)
          ? () {
              setState(() {
                isDragging = true;
                controller.stop();
                controller.reset();
                currentSeconds = 0;

                // 🔥 [수정됨] 0으로 리셋하지 않고 현재 설정된 시간을 잡고 시작!
                _draggedSeconds = targetMaxSeconds; 
              });
            }
          : null,

      onPanUpdate: (!isRunning) ? updateTargetTime : null,

      onPanEnd: (!isRunning)
          ? () {
              setState(() {
                isDragging = false;
                targetMaxSeconds = _draggedSeconds;
                currentSeconds = 0; 
                controller.duration = Duration(seconds: targetMaxSeconds.toInt());
              });
            }
          : null,

      drawnSeconds: displayDrawnSeconds,
      maxScaleSeconds: displayMaxScale,
      isTimer: false,
      digitalSeconds: displayDigitalSeconds,
      onDigitalLongPress: () => _showTimeInputDialog(), 

      // 🔥 [핵심 추가] 시작된 상태에서는 최상단(MAX) 눈금만 표시!
      indicatorModeOverride: (!hasStarted || isDragging)
          ? null 
          : "max_only", 
    );
  }
}
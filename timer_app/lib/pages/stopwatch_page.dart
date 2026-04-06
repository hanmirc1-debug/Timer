import 'package:flutter/material.dart';
import 'dart:math';
import 'shared_design.dart';

class StopwatchPage extends StatefulWidget {
  final ValueChanged<bool> onRunningChanged;
  final GlobalKey clockKey; // 🔥 추가
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
  double targetMaxSeconds = 60;
  double _draggedSeconds = 0;
  double currentSeconds = 0;

  bool isDragging = false;
  bool isRunning = false;
  bool hasStarted = false;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(
          vsync: this,
          duration: Duration(seconds: targetMaxSeconds.toInt()),
        )..addListener(() {
          setState(() => currentSeconds = controller.value * targetMaxSeconds);
        });
  }

  void start() {
    controller.duration = Duration(seconds: targetMaxSeconds.toInt());
    controller.reset();
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

    setState(() {
      _draggedSeconds = (angle / (2 * pi)) * 60;
      if (_draggedSeconds == 0) _draggedSeconds = 60;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void toggle() {
    isRunning ? stop() : start();
  }

  @override
  Widget build(BuildContext context) {
    double displayMaxScale = hasStarted ? targetMaxSeconds : 60.0;
    double displayDrawnSeconds = 0;
    double displayDigitalSeconds = 0;

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

    // 🌟 여기도 수십 줄의 코드를 BaseClockLayout으로 깔끔하게 교체!
    return BaseClockLayout(
      key: widget.clockKey, // 🔥 추가
      isRunning: isRunning,
      onTapToggle: () {},
      // 드래그 설정 (동작 안하고, 시작 안했을 때만 활성화)
      onPanStart: (!isRunning)
          ? () {
              setState(() {
                isDragging = true;
                controller.stop(); // 🔥 혹시 남아있는거 제거
                controller.reset(); // 🔥 완전 초기화

                currentSeconds = 0; // 🔥 기존 시간 제거
              });
            }
          : null,

      onPanUpdate: (!isRunning) ? updateTargetTime : null,

      onPanEnd: (!isRunning)
          ? () {
              setState(() {
                isDragging = false;

                targetMaxSeconds = _draggedSeconds;
                currentSeconds = 0; // 🔥 다시 0부터 시작하도록

                controller.duration = Duration(
                  seconds: targetMaxSeconds.toInt(),
                );
              });
            }
          : null,

      drawnSeconds: displayDrawnSeconds,
      maxScaleSeconds: displayMaxScale,
      isTimer: false,
      digitalSeconds: displayDigitalSeconds,
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:math';
import 'shared_design.dart';

class StopwatchPage extends StatefulWidget {
  final ValueChanged<bool> onRunningChanged;
  const StopwatchPage({super.key, required this.onRunningChanged});

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> with SingleTickerProviderStateMixin {
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
    controller = AnimationController(vsync: this, duration: Duration(seconds: targetMaxSeconds.toInt()))
      ..addListener(() {
        setState(() => currentSeconds = controller.value * targetMaxSeconds);
      });
  }

  void start() {
    controller.duration = Duration(seconds: targetMaxSeconds.toInt());
    if (currentSeconds == 0) controller.reset();
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
      isRunning: isRunning,
      onTapToggle: () => isRunning ? stop() : start(),
      
      // 드래그 설정 (동작 안하고, 시작 안했을 때만 활성화)
      onPanStart: (!isRunning && !hasStarted) ? () {
        setState(() {
          isDragging = true;
          controller.reset();
        });
      } : null,
      onPanUpdate: (!isRunning && !hasStarted) ? updateTargetTime : null,
      onPanEnd: (!isRunning && !hasStarted) ? () {
        setState(() {
          isDragging = false;
          targetMaxSeconds = _draggedSeconds;
        });
      } : null,
      
      drawnSeconds: displayDrawnSeconds,
      maxScaleSeconds: displayMaxScale,
      isTimer: false,
      digitalSeconds: displayDigitalSeconds,
    );
  }
}
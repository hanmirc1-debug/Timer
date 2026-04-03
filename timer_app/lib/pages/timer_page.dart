import 'package:flutter/material.dart';
import 'dart:math';
import 'shared_design.dart';

class TimerAppPage extends StatefulWidget {
  final ValueChanged<bool> onRunningChanged;
  const TimerAppPage({super.key, required this.onRunningChanged});

  @override
  State<TimerAppPage> createState() => _TimerAppPageState();
}

class _TimerAppPageState extends State<TimerAppPage> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  double targetRedSeconds = 60; 
  double currentRedSeconds = 60;
  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 60))
      ..addListener(() {
        setState(() => currentRedSeconds = controller.value * targetRedSeconds);
      });
  }

  void start() {
    controller.duration = Duration(seconds: targetRedSeconds.toInt());
    controller.reverse(from: controller.value == 0.0 ? 1.0 : controller.value);
    setState(() => isRunning = true);
    widget.onRunningChanged(true);
  }

  void stop() {
    controller.stop();
    setState(() => isRunning = false);
    widget.onRunningChanged(false);
  }

  void updateStartTime(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    double angle = atan2(dy, dx);
    double clockwiseFromTop = angle - (-pi / 2);
    if (clockwiseFromTop < 0) clockwiseFromTop += 2 * pi;

    double whiteAmount = (clockwiseFromTop / (2 * pi)) * 60;

    setState(() {
      targetRedSeconds = 60 - whiteAmount;
      if (targetRedSeconds <= 0 || targetRedSeconds >= 60) targetRedSeconds = 60;
      currentRedSeconds = targetRedSeconds;
      controller.duration = Duration(seconds: targetRedSeconds.toInt());
      controller.value = 1.0;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 핵심! 수십 줄의 껍데기 코드를 한 줄의 BaseClockLayout으로 압축했습니다.
    return BaseClockLayout(
      isRunning: isRunning,
      onTapToggle: () => isRunning ? stop() : start(), // 누르면 시작/정지
      onPanUpdate: !isRunning ? updateStartTime : null, // 안 돌아갈 때만 드래그 허용
      drawnSeconds: currentRedSeconds,
      maxScaleSeconds: 60.0,
      isTimer: true,
      digitalSeconds: currentRedSeconds,
    );
  }
}
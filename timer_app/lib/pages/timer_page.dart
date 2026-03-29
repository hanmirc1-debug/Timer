import 'package:flutter/material.dart';
import 'dart:math';
import 'shared_design.dart';

class TimerAppPage extends StatefulWidget {
  const TimerAppPage({super.key});

  @override
  State<TimerAppPage> createState() => _TimerAppPageState();
}

class _TimerAppPageState extends State<TimerAppPage> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  double totalSeconds = 60;
  double currentSeconds = 60;
  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: Duration(seconds: totalSeconds.toInt()))
      ..addListener(() {
        setState(() {
          currentSeconds = controller.value * totalSeconds;
        });
      });
  }

  void start() {
    controller.reverse(from: controller.value == 0.0 ? 1.0 : controller.value);
    setState(() => isRunning = true);
  }

  void stop() {
    controller.stop();
    setState(() => isRunning = false);
  }

  void reset() {
    controller.reset();
    controller.value = 1.0;
    setState(() {
      currentSeconds = totalSeconds;
      isRunning = false;
    });
  }

  void updateStartTime(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    double angle = atan2(dx, -dy);
    if (angle < 0) angle += 2 * pi;

    setState(() {
      totalSeconds = (angle / (2 * pi)) * 60;
      if (totalSeconds == 0) totalSeconds = 60;
      controller.duration = Duration(seconds: totalSeconds.toInt());
      currentSeconds = totalSeconds;
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
    // 가로 모드 레이아웃 적용
    return Row(
      children: [
        // 좌측 (빈공간)
        const Expanded(child: SizedBox()),
        
        // 중앙 (시계 + 디지털 숫자)
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 시계
              GestureDetector(
                onPanUpdate: (details) {
                  if (!isRunning) updateStartTime(details.localPosition, const Size(250, 250));
                },
                child: CustomPaint(
                  size: const Size(250, 250),
                  painter: SharedClockPainter(currentSeconds, 60),
                ),
              ),
              const SizedBox(height: 20),
              
              // 디지털 숫자 (00:00:30)
              Text(
                formatDigitalTimeLong(currentSeconds),
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Colors.redAccent, // 타이머는 빨간색 숫자로 유지
                ),
              ),
            ],
          ),
        ),
        
        // 우측 (조작 버튼)
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassButton(text: '시작', onPressed: start),
              const SizedBox(height: 15),
              GlassButton(text: '멈춤', onPressed: stop),
              const SizedBox(height: 15),
              GlassButton(text: '리셋', onPressed: reset),
            ],
          ),
        ),
      ],
    );
  }
}
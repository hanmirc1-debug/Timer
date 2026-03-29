import 'package:flutter/material.dart';
import 'dart:math';
import 'shared_design.dart';

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});

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
    controller.reset(); 
    controller.forward();
    setState(() => isRunning = true);
  }

  void stop() {
    controller.stop();
    setState(() => isRunning = false);
  }

  void reset() {
    controller.reset();
    setState(() {
      currentSeconds = 0;
      targetMaxSeconds = 60;
      isRunning = false;
    });
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // [수정 핵심] 화면 높이를 기준으로 시계 크기(70%)와 디지털 폰트 크기(15%)를 동적 할당
        final availableHeight = constraints.maxHeight;
        final clockSize = availableHeight * 0.7; 
        final digitalFontSize = availableHeight * 0.15; 

        return Stack(
          children: [
            // 1. 시계 & 디지털 시간 (무조건 정중앙 100% 보장)
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onPanStart: (details) => setState(() {
                      isDragging = true;
                      controller.reset();
                    }),
                    onPanUpdate: (details) {
                      if (!isRunning) {
                        updateTargetTime(details.localPosition, Size(clockSize, clockSize));
                      }
                    },
                    onPanEnd: (details) => setState(() {
                      isDragging = false;
                      targetMaxSeconds = _draggedSeconds;
                    }),
                    child: CustomPaint(
                      size: Size(clockSize, clockSize),
                      painter: SharedClockPainter(isDragging ? _draggedSeconds : currentSeconds, 60),
                    ),
                  ),
                  SizedBox(height: availableHeight * 0.05),
                  
                  // 유동적 폰트 크기가 적용된 디지털 텍스트
                  Text(
                    formatDigitalTimeLong(isDragging ? _draggedSeconds : currentSeconds),
                    style: TextStyle(
                      fontSize: digitalFontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            
            // 2. 조작 버튼 (무조건 우측 고정)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 32.0),
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
            ),
          ],
        );
      }
    );
  }
}
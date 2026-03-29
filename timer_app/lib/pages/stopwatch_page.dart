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
    if (currentSeconds == 0) {
      controller.reset();
    }
    controller.forward();
    setState(() {
      isRunning = true;
      hasStarted = true;
    });
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
      _draggedSeconds = 0;
      isRunning = false;
      hasStarted = false;
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
        final availableHeight = constraints.maxHeight;
        final clockSize = availableHeight * 0.7;
        final digitalFontSize = availableHeight * 0.1;

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

        return Stack(
          children: [
            // 1. 단 하나만 존재하는 시계 & 숫자 영역
            Align(
              alignment: const Alignment(0, -0.2), // 중앙에서 살짝 위로 깔끔하게 배치
              child: Column(
                mainAxisSize: MainAxisSize.min, // 겹침 및 오버플로우 완벽 방지
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onPanStart: (details) => setState(() {
                      if (!isRunning && !hasStarted) {
                        isDragging = true;
                        controller.reset();
                      }
                    }),
                    onPanUpdate: (details) {
                      if (!isRunning && !hasStarted) {
                        updateTargetTime(details.localPosition, Size(clockSize, clockSize));
                      }
                    },
                    onPanEnd: (details) => setState(() {
                      if (!isRunning && !hasStarted) {
                        isDragging = false;
                        targetMaxSeconds = _draggedSeconds;
                      }
                    }),
                    child: CustomPaint(
                      size: Size(clockSize, clockSize),
                      painter: SharedClockPainter(displayDrawnSeconds, displayMaxScale),
                    ),
                  ),
                  SizedBox(height: availableHeight * 0.05),

                  Text(
                    formatDigitalTimeLong(displayDigitalSeconds),
                    style: TextStyle(
                      fontSize: digitalFontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),

            // 2. 우측 조작 버튼 영역
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
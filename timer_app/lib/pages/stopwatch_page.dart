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

  // [수정된 핵심] 스탑워치 전용(일반 시계방향) 드래그 계산식으로 복구!
  void updateTargetTime(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    
    // 12시를 0도로 기준 삼아 시계방향으로 각도를 잼
    double angle = atan2(dx, -dy);
    if (angle < 0) angle += 2 * pi;

    setState(() {
      // 드래그한 각도 그대로 정직하게 시간이 됨
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
        final digitalFontSize = availableHeight * 0.12;

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
            Align(
              alignment: const Alignment(0, -0.2), 
              child: Column(
                mainAxisSize: MainAxisSize.min, 
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
                      // isTimer: false 를 통해 일반 시계 방향(오른쪽 15, 왼쪽 45)으로 그림
                      painter: SharedClockPainter(displayDrawnSeconds, displayMaxScale, isTimer: false),
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
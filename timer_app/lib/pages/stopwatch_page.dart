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
        final digitalFontSize = availableHeight * 0.07;

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

        // 🌟 핵심 1: 스탑워치도 설정값 감지를 위해 ValueListenableBuilder로 감쌉니다!
        return ValueListenableBuilder<String>(
          valueListenable: globalDisplayMode,
          builder: (context, displayMode, child) {
            return ValueListenableBuilder<String>(
              valueListenable: globalIndicatorMode,
              builder: (context, indicatorMode, child) {
                return Stack(
                  children: [
                    Align(
                      alignment: const Alignment(0, -0.2), 
                      child: Column(
                        mainAxisSize: MainAxisSize.min, 
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          
                          // 🌟 핵심 2: displayMode에 따라 아날로그 시계 렌더링 분기
                          if (displayMode == "both" || displayMode == "analog")
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
                                painter: SharedClockPainter(
                                  displayDrawnSeconds, 
                                  displayMaxScale, 
                                  isTimer: false,
                                  indicatorMode: globalIndicatorMode.value,
                                ),
                              ),
                            ),
                          
                          // 둘 다 표시할 때만 중간 여백
                          if (displayMode == "both")
                            SizedBox(height: availableHeight * 0.05),

                          // 🌟 핵심 4: displayMode에 따라 디지털 시계 렌더링 분기
                          if (displayMode == "both" || displayMode == "digital")
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
                    
                    // 우측 버튼 영역 (그대로 유지)
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
        );
      }
    );
  }
}
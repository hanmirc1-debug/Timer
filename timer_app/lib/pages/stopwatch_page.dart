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
  
  double targetMaxSeconds = 60; // 기본 max 60초
  double _draggedSeconds = 0;   // 드래그 임시 값
  double currentSeconds = 0;    // 진행된 시간
  
  bool isDragging = false;
  bool isRunning = false;
  bool hasStarted = false;      // 시작 버튼을 한 번이라도 눌렀는지 여부

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: Duration(seconds: targetMaxSeconds.toInt()))
      ..addListener(() {
        setState(() => currentSeconds = controller.value * targetMaxSeconds);
      });
  }

  void start() {
    // 2. 시작 누르면 컨트롤러의 duration을 설정한 max 시간(예: 15초)으로 변경
    controller.duration = Duration(seconds: targetMaxSeconds.toInt());
    
    if (currentSeconds == 0) {
      controller.reset();
    }
    controller.forward();
    
    setState(() {
      isRunning = true;
      hasStarted = true; // 시작되었음을 알림 (Max 스케일 변경을 위해)
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
      targetMaxSeconds = 60; // 다시 60초 시계로 복귀
      _draggedSeconds = 0;
      isRunning = false;
      hasStarted = false; // 초기 상태로 복귀
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
        final digitalFontSize = availableHeight * 0.15; 

        // [핵심 로직] 상태에 따라 화면에 그릴 값을 다르게 설정
        double displayMaxScale = hasStarted ? targetMaxSeconds : 60.0;
        
        double displayDrawnSeconds = 0;
        double displayDigitalSeconds = 0;

        if (isDragging) {
          // 1) 드래그 중: 드래그하는 위치(임시 값)를 보여줌
          displayDrawnSeconds = _draggedSeconds;
          displayDigitalSeconds = _draggedSeconds;
        } else if (!hasStarted) {
          // 2) 손을 뗐지만 아직 시작 안 함: 설정한 목표치(예: 15초)를 그대로 유지
          displayDrawnSeconds = targetMaxSeconds;
          displayDigitalSeconds = targetMaxSeconds;
        } else {
          // 3) 시작 버튼 누름: 실제 흘러가는 시간 표시 (MAX 스케일이 바뀌었으므로 0부터 차오름)
          displayDrawnSeconds = currentSeconds;
          displayDigitalSeconds = currentSeconds;
        }

        return Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onPanStart: (details) => setState(() {
                      // 실행 중이 아닐 때만 드래그 허용
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
                        targetMaxSeconds = _draggedSeconds; // 드래그 끝날 때 목표 MAX 시간 확정
                      }
                    }),
                    child: CustomPaint(
                      size: Size(clockSize, clockSize),
                      // 상황에 맞춰 계산된 값과 MAX 스케일을 페인터에 전달
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
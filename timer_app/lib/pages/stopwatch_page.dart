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
  
  double targetMaxSeconds = 60; // 드래그로 설정하는 '목표 MAX 시간'
  double _draggedSeconds = 0;   // 드래그 시 보여지는 임시 시간
  double currentSeconds = 0;   // 0부터 증가하는 현재 진행 시간
  
  bool isDragging = false;
  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    // 초기 컨트롤러 설정 (60초 기본)
    controller = AnimationController(vsync: this, duration: Duration(seconds: targetMaxSeconds.toInt()))
      ..addListener(() {
        setState(() {
          currentSeconds = controller.value * targetMaxSeconds;
        });
      });
  }

  void start() {
    // 2. 중요: 시작할 때 컨트롤러의 duration을 드래그로 설정한 MAX 시간으로 업데이트
    controller.duration = Duration(seconds: targetMaxSeconds.toInt());
    
    // 3. 시작 시 0초부터 MAX까지 증가
    // 사용자가 '전부 빨간색으로 채워진 상태'를 원하신다면 logic을 count down으로 바꿔야 하지만,
    // 스탑워치(count up)이므로 0부터 시작합니다. 드래그로 MAX를 설정한 후
    // 0부터 시작해서 MAX가 되면 꽉 차게 됩니다.
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
      targetMaxSeconds = 60; // 기본으로 리셋
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
      
      // 드래그가 끝나기 전까지는 임시 값만 업데이트
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 6. 제목 없앰, 4. 디지털 숫자 시계 밑에 위치
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
                onPanStart: (details) => setState(() {
                  isDragging = true;
                  controller.reset(); // 드래그 시작 시 초기화
                }),
                onPanUpdate: (details) {
                  if (!isRunning) updateTargetTime(details.localPosition, const Size(250, 250));
                },
                onPanEnd: (details) => setState(() {
                  isDragging = false;
                  targetMaxSeconds = _draggedSeconds; // 드래그 끝날 때 MAX 시간 설정
                }),
                child: CustomPaint(
                  size: const Size(250, 250),
                  // 1. 드래그 중일 때 빨간색(임시 값)이 보이도록 함
                  painter: SharedClockPainter(isDragging ? _draggedSeconds : currentSeconds, 60),
                ),
              ),
              const SizedBox(height: 20),
              
              // 디지털 숫자 (00:00:15)
              Text(
                formatDigitalTimeLong(isDragging ? _draggedSeconds : currentSeconds),
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
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
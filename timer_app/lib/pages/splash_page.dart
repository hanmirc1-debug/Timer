import 'package:flutter/material.dart';
import 'dart:math';
import 'package:timer_app/main.dart'; // MainScreen을 인식하기 위해 필요
import 'package:timer_app/pages/shared_design.dart'; 

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

@override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      // 🔥 속도를 더 빠르게 하고 싶다면 seconds를 1로 줄이세요! (1초만에 꽉 참)
      //duration: const Duration(seconds: 1), 
      
      // 💡 만약 아주 미세하게 1.5초로 하고 싶다면 이렇게 밀리초(milliseconds)를 쓰시면 됩니다!
       duration: const Duration(milliseconds: 750), 
    );

    // 애니메이션 완료 후 메인 화면(MainScreen)으로 이동
    _controller.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 요청하신 색상으로 고정
    const Color fixedBgColor = Color(0xFF252528); // 매트 다크
    const Color fixedClockColor = Color.fromARGB(255, 185, 70, 70); // 벽돌색

    return Scaffold(
      backgroundColor: fixedBgColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(120, 120), // 로고 타이머 크기
              painter: SplashTimerPainter(
                progress: _controller.value,
                accentColor: fixedClockColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

// 🎨 차오르는 타이머 페인터 (배경 원 제거 버전)
class SplashTimerPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  SplashTimerPainter({required this.progress, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // ✅ 1. 기존에 있던 배경 원(회색) 그리는 코드를 삭제했습니다.

    // 2. 점점 차오르는 부채꼴 그리기
    final progressPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    const startAngle = -pi / 2; // 12시 방향 시작
    final sweepAngle = 2 * pi * progress; // 진행도에 따라 회전

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true, // 중심점까지 채워서 부채꼴 모양 생성
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SplashTimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

// 1. floating 느낌의 리퀴드 글래스 버튼
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const GlassButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 5,
      borderRadius: BorderRadius.circular(25.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: InkWell(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(color: Colors.black.withOpacity(0.1)),
              ),
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 2. 상단 플로팅 메뉴 버튼 (점 세개)
class FloatingGlassMenuButton extends StatelessWidget {
  FloatingGlassMenuButton({super.key});
  final GlobalKey _buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 3,
      borderRadius: BorderRadius.circular(25),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.black.withOpacity(0.1)),
            ),
            child: IconButton(
              key: _buttonKey,
              icon: const Icon(Icons.more_horiz, size: 24),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
  }
}

// 3. 상단 플로팅 스위치 버튼
class FloatingGlassSwitchButton extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const FloatingGlassSwitchButton({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 3,
      borderRadius: BorderRadius.circular(25),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.black.withOpacity(0.1)),
            ),
            child: Switch(
              value: value,
              activeColor: Colors.black, 
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}

// 4. 시계 그리기 (숫자 반대방향 + 그리는 로직 변경)
class SharedClockPainter extends CustomPainter {
  final double drawnSeconds;
  final double maxScaleSeconds;
  final bool isTimer; // 타이머 여부에 따라 그리는 시작점이 다름

  SharedClockPainter(this.drawnSeconds, this.maxScaleSeconds, {this.isTimer = true});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 빨간색 부채꼴 크기
    final sweepAngle = (drawnSeconds / maxScaleSeconds) * 2 * pi;
    
    double startAngle;
    if (isTimer) {
      // 타이머: 드래그한 끝 지점(하얀색이 끝나는 곳)부터 시계방향으로 칠해서 12시에 끝남
      startAngle = -pi / 2 + ((maxScaleSeconds - drawnSeconds) / maxScaleSeconds) * 2 * pi;
    } else {
      // 스탑워치: 무조건 12시에서 시작
      startAngle = -pi / 2;
    }

    final paintArc = Paint()
      ..color = Colors.redAccent.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    if (drawnSeconds > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paintArc,
      );
    }

    final double relativeFontSize = radius * 0.15;
    final double relativePadding = radius * 0.8;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < maxScaleSeconds; i += 5) {
      double angle;
      // 여기서 스탑워치와 타이머의 숫자 방향이 갈립니다!
      if (isTimer) {
        // 타이머: 반시계 방향 (오른쪽이 45, 왼쪽이 15)
        angle = -pi / 2 - (i / maxScaleSeconds) * 2 * pi;
      } else {
        // 스탑워치: 정방향 시계 (오른쪽이 15, 왼쪽이 45)
        angle = -pi / 2 + (i / maxScaleSeconds) * 2 * pi;
      }
      final x = center.dx + relativePadding * cos(angle);
      final y = center.dy + relativePadding * sin(angle);

      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(
          fontSize: relativeFontSize,
          color: Colors.black, 
          fontWeight: FontWeight.bold
        ),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 5. 디지털 폰트 함수
String formatDigitalTimeLong(double seconds) {
  int s = seconds.toInt();
  int h = s ~/ 3600;
  int m = (s % 3600) ~/ 60;
  s = s % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
import 'package:flutter/material.dart';
import 'package:timer_app/widgets/popup_menu.dart';
import 'dart:math';
import 'dart:ui';

// 1. floating 느낌의 리퀴드 글래스 버튼 (기존꺼 수정)
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const GlassButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // 배경 투명
      elevation: 5, // 그림자 추가로 띄움
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

// 1. 상단 플로팅 메뉴 버튼 (점 세개)
class FloatingGlassMenuButton extends StatelessWidget {
  FloatingGlassMenuButton({super.key});

  final GlobalKey _buttonKey = GlobalKey(); // 추가

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
              key: _buttonKey, // 추가
              icon: const Icon(Icons.more_horiz, size: 24),
              onPressed: () {
                final RenderBox box =
                    _buttonKey.currentContext!.findRenderObject() as RenderBox;

                final position = box.localToGlobal(Offset.zero);
                final size = box.size;

                showDialog(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (_) => CustomPopupMenu(
                    position: position,
                    buttonSize: size,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// 2. 상단 플로팅 스위치 버튼
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
            child: Row(
              children: [
                // 2. 글자 없앰 (무슨 모드인지 알려주지 않음)
                Switch(
                  value: value,
                  activeColor: Colors.black, 
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 5. 시계 테두리 없앰 (drawCircle 삭제)
class SharedClockPainter extends CustomPainter {
  final double drawnSeconds;
  final double maxScaleSeconds;

  SharedClockPainter(this.drawnSeconds, this.maxScaleSeconds);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 시계 테두리(drawCircle) 코드 삭제

    // 빨간색 부채꼴(Pie) 영역
    final sweepAngle = (drawnSeconds / maxScaleSeconds) * 2 * pi;
    final paintArc = Paint()
      ..color = Colors.redAccent.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, 
      sweepAngle,
      true, 
      paintArc,
    );

    // 숫자 표시 (기존 유지)
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < maxScaleSeconds; i += 5) {
      final angle = (i / maxScaleSeconds) * 2 * pi;
      final x = center.dx + (radius - 25) * sin(angle);
      final y = center.dy - (radius - 25) * cos(angle);

      textPainter.text = TextSpan(
        text: '$i',
        style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 4. 디지털 폰트 HH:MM:SS 포맷 함수
String formatDigitalTimeLong(double seconds) {
  int s = seconds.toInt();
  int h = s ~/ 3600;
  int m = (s % 3600) ~/ 60;
  s = s % 60;
  
  // 00:00:00 형태로 출력
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
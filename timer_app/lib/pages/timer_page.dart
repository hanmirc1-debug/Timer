import 'package:flutter/material.dart';
import 'dart:math';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  double totalSeconds = 60; // 설정된 시간
  double currentSeconds = 0;

  bool isRunning = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalSeconds.toInt()),
    )
      ..addListener(() {
        setState(() {
          currentSeconds = controller.value * totalSeconds;
        });
      });
  }

  void start() {
    controller.forward(from: controller.value);
    isRunning = true;
  }

  void stop() {
    controller.stop();
    isRunning = false;
  }

  void reset() {
    controller.reset();
    currentSeconds = 0;
  }

  // 드래그로 시간 설정
  void updateTime(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    double angle = atan2(dx, -dy);
    if (angle < 0) angle += 2 * pi;

    setState(() {
      totalSeconds = (angle / (2 * pi)) * 60;
      controller.duration = Duration(seconds: totalSeconds.toInt());
      controller.reset();
      currentSeconds = 0;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displaySeconds = (totalSeconds - currentSeconds).clamp(0, totalSeconds);

    return Scaffold(
      appBar: AppBar(title: const Text('Timer')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              if (!isRunning) {
                updateTime(details.localPosition, const Size(250, 250));
              }
            },
            child: CustomPaint(
              size: const Size(250, 250),
              painter: ClockPainter(currentSeconds, totalSeconds),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            '${displaySeconds.toInt()} 초',
            style: const TextStyle(fontSize: 32),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: start, child: const Text('시작')),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: stop, child: const Text('멈춤')),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: reset, child: const Text('리셋')),
            ],
          ),
        ],
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final double current;
  final double total;

  ClockPainter(this.current, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintCircle = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, paintCircle);

    // 숫자 표시 (12개)
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < 60; i += 5) {
      final angle = (i / 60) * 2 * pi;
      final x = center.dx + (radius - 20) * sin(angle);
      final y = center.dy - (radius - 20) * cos(angle);

      textPainter.text = TextSpan(
        text: '$i',
        style: const TextStyle(fontSize: 12, color: Colors.black),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // 초침
    final angle = (current / total) * 2 * pi;

    final handPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3;

    final handLength = radius * 0.8;

    final handX = center.dx + handLength * sin(angle);
    final handY = center.dy - handLength * cos(angle);

    canvas.drawLine(center, Offset(handX, handY), handPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
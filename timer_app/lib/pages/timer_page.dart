import 'package:flutter/material.dart';
import 'dart:math';
import 'shared_design.dart';

class TimerAppPage extends StatefulWidget {
  const TimerAppPage({super.key});

  @override
  State<TimerAppPage> createState() => _TimerAppPageState();
}

class _TimerAppPageState extends State<TimerAppPage> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  double totalSeconds = 60;
  double currentSeconds = 60;
  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: Duration(seconds: totalSeconds.toInt()))
      ..addListener(() {
        setState(() => currentSeconds = controller.value * totalSeconds);
      });
  }

  void start() {
    controller.reverse(from: controller.value == 0.0 ? 1.0 : controller.value);
    setState(() => isRunning = true);
  }

  void stop() {
    controller.stop();
    setState(() => isRunning = false);
  }

  void reset() {
    controller.reset();
    controller.value = 1.0;
    setState(() {
      currentSeconds = totalSeconds;
      isRunning = false;
    });
  }

  void updateStartTime(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    double angle = atan2(dx, -dy);
    if (angle < 0) angle += 2 * pi;

    setState(() {
      totalSeconds = (angle / (2 * pi)) * 60;
      if (totalSeconds == 0) totalSeconds = 60;
      controller.duration = Duration(seconds: totalSeconds.toInt());
      currentSeconds = totalSeconds;
      controller.value = 1.0;
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

        return Stack(
          children: [
            Align(
              alignment: const Alignment(0, -0.2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onPanUpdate: (details) {
                      if (!isRunning) {
                        updateStartTime(details.localPosition, Size(clockSize, clockSize));
                      }
                    },
                    child: CustomPaint(
                      size: Size(clockSize, clockSize),
                      painter: SharedClockPainter(currentSeconds, 60),
                    ),
                  ),
                  SizedBox(height: availableHeight * 0.05),
                  
                  Text(
                    formatDigitalTimeLong(currentSeconds),
                    style: TextStyle(
                      fontSize: digitalFontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: const Color.fromARGB(255, 0, 0, 0), 
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
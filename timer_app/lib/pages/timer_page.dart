import 'package:flutter/material.dart';
import 'dart:math';
import 'shared_design.dart';

class TimerAppPage extends StatefulWidget {
  const TimerAppPage({super.key});

  @override
  State<TimerAppPage> createState() => _TimerAppPageState();
}

class _TimerAppPageState extends State<TimerAppPage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  double targetRedSeconds = 60; // 60초 꽉 찬 상태(전체 빨간색)가 기본값
  double currentRedSeconds = 60;
  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 60))
          ..addListener(() {
            setState(
              () => currentRedSeconds = controller.value * targetRedSeconds,
            );
          });
  }

  void start() {
    controller.duration = Duration(seconds: targetRedSeconds.toInt());
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
      currentRedSeconds = targetRedSeconds;
      isRunning = false;
    });
  }

  void updateStartTime(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    // 드래그한 지점의 각도 계산 (12시 기준 시계방향)
    double angle = atan2(dy, dx);
    double clockwiseFromTop = angle - (-pi / 2);
    if (clockwiseFromTop < 0) clockwiseFromTop += 2 * pi;

    // 드래그한 거리만큼이 '하얀색'이 됨
    double whiteAmount = (clockwiseFromTop / (2 * pi)) * 60;

    setState(() {
      // 전체 60에서 하얀색을 뺀 나머지가 실제 타이머 시간(빨간색)
      targetRedSeconds = 60 - whiteAmount;
      if (targetRedSeconds <= 0 || targetRedSeconds >= 60) {
        targetRedSeconds = 60; // 0이나 60이면 다시 전체 빨간색으로
      }
      currentRedSeconds = targetRedSeconds;
      controller.duration = Duration(seconds: targetRedSeconds.toInt());
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
        final digitalFontSize = availableHeight * 0.07;

        // 🌟 핵심 1: 화면 전체를 ValueListenableBuilder로 감싸서 즉각 반응하게 만듭니다!
        return AnimatedBuilder(
          animation: Listenable.merge([
            globalDisplayMode,
            globalIndicatorMode,
            globalDigitalStyle,
          ]),
          builder: (context, child) {
            // 현재 설정값 3가지를 모두 가져옵니다.
            String displayMode = globalDisplayMode.value;
            bool isDot = globalIndicatorMode.value == "dot";
            String digitalStyle = globalDigitalStyle.value; // 👈 새로 추가된 폰트 스타일!
            return Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -0.2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🌟 핵심 2: displayMode가 "both"이거나 "analog"일 때만 아날로그 시계 렌더링
                      if (displayMode == "both" || displayMode == "analog")
                        GestureDetector(
                          onPanUpdate: (details) {
                            if (!isRunning) {
                              updateStartTime(
                                details.localPosition,
                                Size(clockSize, clockSize),
                              );
                            }
                          },
                          child: CustomPaint(
                            size: Size(clockSize, clockSize),
                            painter: SharedClockPainter(
                              currentRedSeconds,
                              60,
                              isTimer: true,
                              indicatorMode: globalIndicatorMode.value,
                            ),
                          ),
                        ),

                      // 둘 다 표시할 때만 중간 여백
                      if (displayMode == "both")
                        SizedBox(height: availableHeight * 0.05),

                      // 🌟 핵심 3: displayMode가 "both"이거나 "digital"일 때만 디지털 텍스트 렌더링
                      if (displayMode == "both" || displayMode == "digital")
                        CustomDigitalClock(
                          seconds: currentRedSeconds,
                          styleMode: digitalStyle, // 👈 팝업에서 선택한 폰트 스타일 적용
                          fontSize: digitalFontSize,
                          defaultColor: Colors.redAccent,
                        ),
                    ],
                  ),
                ),

                // 우측 시작/멈춤/리셋 버튼 영역 (그대로 유지)
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
          },
        );
      },
    );
  }
}

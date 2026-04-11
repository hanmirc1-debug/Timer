import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 💡 햅틱(진동)을 쓰기 위해 필수!
import 'dart:math';
import 'dart:ui';
import 'settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =========================================================
// 🌟 0. 앱 전체 공유 설정값
// =========================================================
// 1. 타이머/스탑워치 모드 선택 (추가됨)
final ValueNotifier<bool> globalIsTimerMode = ValueNotifier<bool>(true);

// 2. 시계 표시 (both, analog, digital)
final ValueNotifier<String> globalDisplayMode = ValueNotifier<String>("both");

// 3. 숫자 표시 (number, dot, none)
final ValueNotifier<String> globalIndicatorMode = ValueNotifier<String>(
  "number",
);

// 4. 디지털 폰트 스타일 (default, segment, flip)
final ValueNotifier<String> globalDigitalStyle = ValueNotifier<String>(
  "default",
);

// 5. 폰트 사이즈 (Small, Medium, Large) (추가됨)
final ValueNotifier<String> globalDigitalFontSize = ValueNotifier<String>(
  "Medium",
);

// 6. 햅틱 진동 세기 (Soft, Medium, Strong) (추가됨)
final ValueNotifier<String> globalHapticIntensity = ValueNotifier<String>(
  "Medium",
);

// 7. 알림
final ValueNotifier<bool> globalAlarmEnabled = ValueNotifier<bool>(true);
final ValueNotifier<String> globalAlarmSound = ValueNotifier<String>(
  "기본음 (Bell)",
);
// 8. BGM 설정
final ValueNotifier<bool> globalBgmEnabled = ValueNotifier<bool>(false);
final ValueNotifier<String> globalBgmTrack = ValueNotifier<String>(
  "백색소음 (White Noise)",
);

// 테마 색상들
// 1. 배경색 (고급스러운 다크 그레이)
final ValueNotifier<Color> globalBgColor = ValueNotifier(
  const Color(0xFF252528),
);

// 2. 아날로그 시계 채워지는 색 (배경보다 살짝 밝은 중간 회색)
//final ValueNotifier<Color> globalClockColor = ValueNotifier(const Color(0xFF4A4A4D));
final ValueNotifier<Color> globalClockColor = ValueNotifier(
  const Color.fromARGB(255, 185, 70, 70),
);

// 3. 디지털 시계 숫자 색 (완전 흰색이 아닌 약간 따뜻한 오프-화이트)
final ValueNotifier<Color> globalDigitalColor = ValueNotifier(
  const Color(0xFF8E8E93),
);
// 3. 디지털 시계 숫자 색 (완전 흰색이 아닌 약간 따뜻한 오프-화이트)
//final ValueNotifier<Color> globalDigitalColor = ValueNotifier(const Color(0xFFE5E5EA));

// 4. 시계 테두리 눈금 및 숫자 색 (차분한 시스템 그레이)
final ValueNotifier<Color> globalIndicatorColor = ValueNotifier(
  const Color(0xFF8E8E93),
);

// =========================================================
// 🌟 0-2. 설정 저장/불러오기 함수 (SharedPreferences 사용
// =========================================================
Future<void> saveSettings() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setBool("isTimerMode", globalIsTimerMode.value);
  await prefs.setString("displayMode", globalDisplayMode.value);
  await prefs.setString("indicatorMode", globalIndicatorMode.value);
  await prefs.setString("digitalStyle", globalDigitalStyle.value);
  await prefs.setString("fontSize", globalDigitalFontSize.value);
  await prefs.setString("haptic", globalHapticIntensity.value);

  await prefs.setInt("bgColor", globalBgColor.value.value);
  await prefs.setInt("clockColor", globalClockColor.value.value);
  await prefs.setInt("digitalColor", globalDigitalColor.value.value);
  await prefs.setInt("indicatorColor", globalIndicatorColor.value.value);
}

// =========================================================
// 앱 시작 시 설정 불러오기
// =========================================================
Future<void> loadSettings() async {
  final prefs = await SharedPreferences.getInstance();

  globalIsTimerMode.value = prefs.getBool("isTimerMode") ?? true;
  globalDisplayMode.value = prefs.getString("displayMode") ?? "both";
  globalIndicatorMode.value = prefs.getString("indicatorMode") ?? "number";
  globalDigitalStyle.value = prefs.getString("digitalStyle") ?? "default";
  globalDigitalFontSize.value = prefs.getString("fontSize") ?? "Medium";
  globalHapticIntensity.value = prefs.getString("haptic") ?? "Medium";

  globalBgColor.value = Color(prefs.getInt("bgColor") ?? 0xFF252528);
  globalClockColor.value = Color(prefs.getInt("clockColor") ?? 0xFFB94646);
  globalDigitalColor.value = Color(prefs.getInt("digitalColor") ?? 0xFF8E8E93);
  globalIndicatorColor.value = Color(
    prefs.getInt("indicatorColor") ?? 0xFF8E8E93,
  );
}

void initSettingsListener() {
  globalBgColor.addListener(saveSettings);
  globalClockColor.addListener(saveSettings);
  globalDigitalColor.addListener(saveSettings);
  globalIndicatorColor.addListener(saveSettings);

  globalIsTimerMode.addListener(saveSettings);
  globalDisplayMode.addListener(saveSettings);
  globalIndicatorMode.addListener(saveSettings);
  globalDigitalStyle.addListener(saveSettings);
  globalDigitalFontSize.addListener(saveSettings);
  globalHapticIntensity.addListener(saveSettings);
}

// =========================================================
// 🌟 햅틱 엔진 (1눈금마다 톡톡 치는 진동 울리기)
// =========================================================
class DragHapticManager {
  static int _lastTick = -1;

  static void checkAndTrigger(int currentTick) {
    if (_lastTick != currentTick) {
      _lastTick = currentTick;

      String intensity = globalHapticIntensity.value;

      // 💡 "None" 이면 아무 진동도 울리지 않고 종료!
      if (intensity == "None") return;

      if (intensity == "Soft") {
        HapticFeedback.lightImpact();
      } else if (intensity == "Medium") {
        HapticFeedback.mediumImpact();
      } else if (intensity == "Strong") {
        HapticFeedback.heavyImpact();
      }
    }
  }
}

// =========================================================
// 1. 공통 깔끔한 껍데기
// =========================================================
class FloatingGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FloatingGlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(5),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      borderRadius: BorderRadius.circular(20.0),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

// 2. 텍스트 버튼 (시작, 멈춤, 리셋)
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const GlassButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingGlassContainer(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// 3. 상단 메뉴 버튼 (점 세개)
class FloatingGlassMenuButton extends StatelessWidget {
  final Color backgroundColor;

  FloatingGlassMenuButton({super.key, required this.backgroundColor});

  final GlobalKey _buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    Color iconColor = backgroundColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(
          top: screenHeight * 0.00,
          left: screenWidth * 0.00,
        ),
        child: FloatingGlassContainer(
          padding: EdgeInsets.zero,
          child: IconButton(
            key: _buttonKey,
            padding: EdgeInsets.all(screenWidth * 0.02),
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.more_horiz,
              size: screenWidth * 0.04,
              color: iconColor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ),
      ),
    );
  }
}

// =========================================================
// 5. 시계 디자인 페인터 (고급스러운 3D 질감 추가!)
// =========================================================
class SharedClockPainter extends CustomPainter {
  final double drawnSeconds;
  final double maxScaleSeconds;
  final bool isTimer;
  final String indicatorMode;

  SharedClockPainter(
    this.drawnSeconds,
    this.maxScaleSeconds, {
    this.isTimer = true,
    this.indicatorMode = "number",
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.5;

    // =============================================================
    // 🌟 [감성 디테일 1] 시계판 바닥에 입체적인 질감 그리기
    // =============================================================

    // 1. 바깥쪽 부드러운 그림자 (시계판이 화면에서 살짝 떠 보이게 만듦)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        15.0,
      ); // 뽀얗게 퍼지는 그림자
    canvas.drawCircle(center + const Offset(4, 4), radius, shadowPaint);

    // 2. 시계판 진짜 바탕색 (배경색과 동일하게 칠함)
    final facePaint = Paint()..color = globalBgColor.value;
    canvas.drawCircle(center, radius, facePaint);

    // 3. 유리막 같은 광택/질감 레이어 (배경보다 아주아주 살짝 밝게 덮어줌)
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, highlightPaint);

    // 4. 시계판 맨 바깥쪽 은은한 테두리 림 (고급 시계 마감 느낌)
    final rimPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, rimPaint);

    // =============================================================

    // 채워지는 부채꼴 크기 계산
    final sweepAngle = (drawnSeconds / maxScaleSeconds) * 2 * pi;
    double startAngle = isTimer
        ? -pi / 2 +
              ((maxScaleSeconds - drawnSeconds) / maxScaleSeconds) * 2 * pi
        : -pi / 2;

    final paintArc = Paint()
      ..color = globalClockColor.value
      ..style = PaintingStyle.fill;

    if (drawnSeconds > 0) {
      canvas.drawArc(
        // 💡 팁: 테두리(림)를 덮어버리지 않도록 반지름을 0.98을 곱해 살짝 작게 그립니다!
        Rect.fromCircle(center: center, radius: radius * 0.98),
        startAngle,
        sweepAngle,
        true,
        paintArc,
      );
    }

    // 눈금선 그리기 (사진처럼 약간 더 차분하게 조정)
    final tickPaint = Paint()
      ..color = globalIndicatorColor.value.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final fiveTickPaint = Paint()
      ..color = globalIndicatorColor.value.withOpacity(0.8)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (int t = 0; t < 60; t++) {
      final angle = (t / 60) * 2 * pi - pi / 2;
      bool isFiveMinute = t % 5 == 0;
      Paint currentPaint = isFiveMinute ? fiveTickPaint : tickPaint;
      double innerRadiusRatio = isFiveMinute ? 0.92 : 0.96;

      canvas.drawLine(
        center +
            Offset(
              cos(angle) * (radius * innerRadiusRatio),
              sin(angle) * (radius * innerRadiusRatio),
            ),
        center + Offset(cos(angle) * radius, sin(angle) * radius),
        currentPaint,
      );
    }

    final double relativeFontSize = radius * 0.1;
    final double relativePadding = radius * 1.08;
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < maxScaleSeconds; i += 5) {
      if (indicatorMode == "none") continue;

      double angle = isTimer
          ? (-pi / 2 - (i / maxScaleSeconds) * 2 * pi)
          : (-pi / 2 + (i / maxScaleSeconds) * 2 * pi);
      final x = center.dx + relativePadding * cos(angle);
      final y = center.dy + relativePadding * sin(angle);

      if (indicatorMode == "dot") {
        final dotPaint = Paint()
          ..color = globalIndicatorColor.value
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), radius * 0.03, dotPaint);
      } else if (indicatorMode == "number") {
        textPainter.text = TextSpan(
          text: '$i',
          style: TextStyle(
            fontSize: relativeFontSize,
            color: globalIndicatorColor.value,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

String formatDigitalTimeLong(double seconds) {
  int s = seconds.toInt();
  int h = s ~/ 3600;
  int m = (s % 3600) ~/ 60;
  s = s % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

// 6. 다기능 디지털 시계 위젯
class CustomDigitalClock extends StatelessWidget {
  final double seconds;
  final String styleMode;
  final double fontSize;
  final Color defaultColor;

  const CustomDigitalClock({
    super.key,
    required this.seconds,
    required this.styleMode,
    required this.fontSize,
    this.defaultColor = Colors.redAccent,
  });

  @override
  Widget build(BuildContext context) {
    String timeString = formatDigitalTimeLong(seconds);

    if (styleMode == "flip") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: timeString.split('').map((char) {
          if (char == ':') {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: fontSize * 0.12,
                    height: fontSize * 0.12,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(1.0),
                    ),
                  ),
                  SizedBox(height: fontSize * 0.25),
                  Container(
                    width: fontSize * 0.12,
                    height: fontSize * 0.12,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(1.0),
                    ),
                  ),
                ],
              ),
            );
          }
          return ClassicFlipDigit(digit: char, fontSize: fontSize);
        }).toList(),
      );
    } else if (styleMode == "segment") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: timeString.split('').map((char) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: SevenSegmentDigit(
              digit: char,
              height: fontSize * 0.9,
              color: defaultColor,
            ),
          );
        }).toList(),
      );
    } else {
      return Text(
        timeString,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
          color: defaultColor,
        ),
      );
    }
  }
}

// 아날로그 플립 카드
class ClassicFlipDigit extends StatefulWidget {
  final String digit;
  final double fontSize;
  const ClassicFlipDigit({
    super.key,
    required this.digit,
    required this.fontSize,
  });
  @override
  State<ClassicFlipDigit> createState() => _ClassicFlipDigitState();
}

class _ClassicFlipDigitState extends State<ClassicFlipDigit>
    with SingleTickerProviderStateMixin {
  late String _currentDigit, _nextDigit;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _currentDigit = widget.digit;
    _nextDigit = widget.digit;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed)
          setState(() => _currentDigit = _nextDigit);
      });
  }

  @override
  void didUpdateWidget(ClassicFlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.digit != oldWidget.digit) {
      _nextDigit = widget.digit;
      _controller.forward(from: 0.0);
    }
  }

  Widget _buildHalf(String digit, bool isTop) {
    return ClipRect(
      child: Align(
        alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
        heightFactor: 0.5,
        child: Container(
          width: widget.fontSize * 0.85,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(
              top: isTop ? const Radius.circular(8.0) : Radius.zero,
              bottom: isTop ? Radius.zero : const Radius.circular(8.0),
            ),
          ),
          child: Text(
            digit,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final isFirstHalf = _animation.value < 0.5;
        Widget topHalf, bottomHalf;

        if (isFirstHalf) {
          final flipValue = _animation.value * 2;
          topHalf = Stack(
            children: [
              _buildHalf(_nextDigit, true),
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.003)
                  ..rotateX(-flipValue * (pi / 2)),
                alignment: Alignment.bottomCenter,
                child: _buildHalf(_currentDigit, true),
              ),
            ],
          );
          bottomHalf = _buildHalf(_currentDigit, false);
        } else {
          final flipValue = (_animation.value - 0.5) * 2;
          topHalf = _buildHalf(_nextDigit, true);
          bottomHalf = Stack(
            children: [
              _buildHalf(_currentDigit, false),
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.003)
                  ..rotateX((1.0 - flipValue) * (pi / 2)),
                alignment: Alignment.topCenter,
                child: _buildHalf(_nextDigit, false),
              ),
            ],
          );
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              topHalf,
              Container(
                height: 2.0,
                width: widget.fontSize * 0.7,
                color: Colors.black87,
              ),
              bottomHalf,
            ],
          ),
        );
      },
    );
  }
}

// 7-세그먼트 LED
class SevenSegmentDigit extends StatelessWidget {
  final String digit;
  final double height;
  final Color color;
  const SevenSegmentDigit({
    super.key,
    required this.digit,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (digit == ':') {
      return Transform(
        transform: Matrix4.skewX(-0.15),
        child: SizedBox(
          width: height * 0.25,
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: height * 0.1,
                height: height * 0.1,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              Container(
                width: height * 0.1,
                height: height * 0.1,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final bool a = ['0', '2', '3', '5', '6', '7', '8', '9'].contains(digit);
    final bool b = ['0', '1', '2', '3', '4', '7', '8', '9'].contains(digit);
    final bool c = [
      '0',
      '1',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
    ].contains(digit);
    final bool d = ['0', '2', '3', '5', '6', '8', '9'].contains(digit);
    final bool e = ['0', '2', '6', '8'].contains(digit);
    final bool f = ['0', '4', '5', '6', '8', '9'].contains(digit);
    final bool g = ['2', '3', '4', '5', '6', '8', '9'].contains(digit);

    double w = height * 0.55;
    double t = height * 0.18;
    double gap = height * 0.05;

    Widget segment(bool active) {
      return Container(
        margin: EdgeInsets.all(gap),
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(t / 2),
        ),
      );
    }

    return Transform(
      transform: Matrix4.skewX(-0.15),
      child: SizedBox(
        width: w,
        height: height,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: t * 0.4,
              right: t * 0.4,
              height: t,
              child: segment(a),
            ),
            Positioned(
              top: t * 0.5,
              right: 0,
              width: t,
              height: height / 2 - t * 0.5,
              child: segment(b),
            ),
            Positioned(
              bottom: t * 0.5,
              right: 0,
              width: t,
              height: height / 2 - t * 0.5,
              child: segment(c),
            ),
            Positioned(
              bottom: 0,
              left: t * 0.4,
              right: t * 0.4,
              height: t,
              child: segment(d),
            ),
            Positioned(
              bottom: t * 0.5,
              left: 0,
              width: t,
              height: height / 2 - t * 0.5,
              child: segment(e),
            ),
            Positioned(
              top: t * 0.5,
              left: 0,
              width: t,
              height: height / 2 - t * 0.5,
              child: segment(f),
            ),
            Positioned(
              top: height / 2 - t / 2,
              left: t * 0.4,
              right: t * 0.4,
              height: t,
              child: segment(g),
            ),
          ],
        ),
      ),
    );
  }
}

typedef ClockPanCallback = void Function(Offset localPosition, Size size);

class BaseClockLayout extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onTapToggle;

  final VoidCallback? onPanStart;
  final ClockPanCallback? onPanUpdate;
  final VoidCallback? onPanEnd;

  final double drawnSeconds;
  final double maxScaleSeconds;
  final bool isTimer;
  final double digitalSeconds;

  final String? indicatorModeOverride;

  const BaseClockLayout({
    super.key,
    required this.isRunning,
    required this.onTapToggle,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    required this.drawnSeconds,
    required this.maxScaleSeconds,
    required this.isTimer,
    required this.digitalSeconds,
    this.indicatorModeOverride, // 🔥 여기 추가
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final clockSize =
            min(constraints.maxWidth, constraints.maxHeight) * 0.7;

        return AnimatedBuilder(
          animation: Listenable.merge([
            globalDisplayMode, globalIndicatorMode, globalDigitalStyle,
            globalClockColor, globalDigitalColor, globalIndicatorColor,
            globalDigitalFontSize, // 👈 폰트 사이즈 실시간 연동
          ]),
          builder: (context, child) {
            String displayMode = globalDisplayMode.value;
            String indicatorMode =
                indicatorModeOverride ?? globalIndicatorMode.value;
            String digitalStyle = globalDigitalStyle.value;

            // 💡 설정한 폰트 사이즈(Small, Medium, Large)에 따라 텍스트 크기 비율 조절
            double fontMultiplier = 1.0;
            if (globalDigitalFontSize.value == "Small") fontMultiplier = 0.7;
            if (globalDigitalFontSize.value == "Large") fontMultiplier = 1.3;
            final digitalFontSize = availableHeight * 0.07 * fontMultiplier;

            return GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: onTapToggle,
              child: Stack(
                children: [
                  Align(
                    alignment: const Alignment(0, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 1. 아날로그 시계 영역
                        if (displayMode == "both" || displayMode == "analog")
                          GestureDetector(
                            onPanStart: onPanStart != null
                                ? (_) => onPanStart!()
                                : null,

                            // 👇👇👇 수정 6. 드래그할 때 햅틱 진동을 발생시킵니다! 👇👇👇
                            onPanUpdate: onPanUpdate != null
                                ? (details) {
                                    // 1눈금 단위 계산 로직
                                    final center = Offset(
                                      clockSize / 2,
                                      clockSize / 2,
                                    );
                                    double angle = atan2(
                                      details.localPosition.dy - center.dy,
                                      details.localPosition.dx - center.dx,
                                    );
                                    double clockwise = angle - (-pi / 2);
                                    if (clockwise < 0) clockwise += 2 * pi;

                                    int currentTick =
                                        ((clockwise / (2 * pi)) * 60).toInt();

                                    // 햅틱 엔진 호출! (눈금이 변할 때만 드르륵 울림)
                                    DragHapticManager.checkAndTrigger(
                                      currentTick,
                                    );

                                    // 원래 시계의 드래그 함수 실행
                                    onPanUpdate!(
                                      details.localPosition,
                                      Size(clockSize, clockSize),
                                    );
                                  }
                                : null,
                            onPanEnd: onPanEnd != null
                                ? (_) => onPanEnd!()
                                : null,

                            child: CustomPaint(
                              size: Size(clockSize, clockSize),
                              painter: SharedClockPainter(
                                drawnSeconds,
                                maxScaleSeconds,
                                isTimer: isTimer,
                                indicatorMode: indicatorMode,
                              ),
                            ),
                          ),

                        // 2. 중간 여백
                        if (displayMode == "both")
                          SizedBox(height: availableHeight * 0.08),

                        // 3. 디지털 텍스트 영역
                        if (displayMode == "both" || displayMode == "digital")
                          FittedBox(
                            // 🔥 추가
                            fit: BoxFit.scaleDown,
                            child: CustomDigitalClock(
                              seconds: digitalSeconds,
                              styleMode: digitalStyle,
                              fontSize: digitalFontSize,
                              defaultColor: globalDigitalColor.value,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

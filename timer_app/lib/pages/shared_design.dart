import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui';
import 'settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart'; 

// =========================================================
// 🌟 0. 앱 전체 공유 설정값
// =========================================================
final ValueNotifier<bool> globalIsTimerMode = ValueNotifier<bool>(true);
final ValueNotifier<String> globalDisplayMode = ValueNotifier<String>("BOTH");
final ValueNotifier<String> globalIndicatorMode = ValueNotifier<String>("NUMBER");
final ValueNotifier<String> globalDigitalStyle = ValueNotifier<String>("DEFAULT");
final ValueNotifier<String> globalDigitalFontSize = ValueNotifier<String>("MEDIUM");
final ValueNotifier<String> globalHapticIntensity = ValueNotifier<String>("MEDIUM");

final ValueNotifier<bool> globalAlarmEnabled = ValueNotifier<bool>(true);
final ValueNotifier<String> globalAlarmSound = ValueNotifier<String>("기본음 (Bell)");
final ValueNotifier<bool> globalBgmEnabled = ValueNotifier<bool>(false);
final ValueNotifier<String> globalBgmTrack = ValueNotifier<String>("백색소음 (White Noise)");

final ValueNotifier<String> globalTimerMaxString = ValueNotifier<String>("60초 (1분)");
final ValueNotifier<double> globalTimerMaxSeconds = ValueNotifier<double>(60.0);

final ValueNotifier<String> globalBgVideoName = ValueNotifier<String>("사용 안 함");

final ValueNotifier<Color> globalBgColor = ValueNotifier(const Color(0xFF252528));
final ValueNotifier<Color> globalClockColor = ValueNotifier(const Color.fromARGB(255, 185, 70, 70));
final ValueNotifier<Color> globalDigitalColor = ValueNotifier(const Color(0xFF8E8E93));
final ValueNotifier<Color> globalIndicatorColor = ValueNotifier(const Color(0xFF8E8E93));

Future<void> saveSettings() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool("isTimerMode", globalIsTimerMode.value);
  await prefs.setString("displayMode", globalDisplayMode.value);
  await prefs.setString("indicatorMode", globalIndicatorMode.value);
  await prefs.setString("digitalStyle", globalDigitalStyle.value);
  await prefs.setString("fontSize", globalDigitalFontSize.value);
  await prefs.setString("haptic", globalHapticIntensity.value);
  await prefs.setString("timerMaxString", globalTimerMaxString.value);
  await prefs.setDouble("timerMaxSeconds", globalTimerMaxSeconds.value);
  
  await prefs.setString("bgVideoName", globalBgVideoName.value); 

  await prefs.setInt("bgColor", globalBgColor.value.value);
  await prefs.setInt("clockColor", globalClockColor.value.value);
  await prefs.setInt("digitalColor", globalDigitalColor.value.value);
  await prefs.setInt("indicatorColor", globalIndicatorColor.value.value);

  await prefs.setBool("alarmEnabled", globalAlarmEnabled.value);
  await prefs.setString("alarmSound", globalAlarmSound.value);
  await prefs.setBool("bgmEnabled", globalBgmEnabled.value);
  await prefs.setString("bgmTrack", globalBgmTrack.value);
}

Future<void> loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  globalIsTimerMode.value = prefs.getBool("isTimerMode") ?? true;
  globalDisplayMode.value = prefs.getString("displayMode") ?? "BOTH";
  globalIndicatorMode.value = prefs.getString("indicatorMode") ?? "NUMBER";
  globalDigitalStyle.value = prefs.getString("digitalStyle") ?? "DEFAULT";
  globalDigitalFontSize.value = prefs.getString("fontSize") ?? "MEDIUM";
  globalHapticIntensity.value = prefs.getString("haptic") ?? "MEDIUM";
  globalTimerMaxString.value = prefs.getString("timerMaxString") ?? "60초 (1분)";
  globalTimerMaxSeconds.value = prefs.getDouble("timerMaxSeconds") ?? 60.0;
  
  globalBgVideoName.value = prefs.getString("bgVideoName") ?? "사용 안 함"; 

  globalBgColor.value = Color(prefs.getInt("bgColor") ?? 0xFF252528);
  globalClockColor.value = Color(prefs.getInt("clockColor") ?? 0xFFB94646);
  globalDigitalColor.value = Color(prefs.getInt("digitalColor") ?? 0xFF8E8E93);
  globalIndicatorColor.value = Color(prefs.getInt("indicatorColor") ?? 0xFF8E8E93);

  globalAlarmEnabled.value = prefs.getBool("alarmEnabled") ?? true;
  globalAlarmSound.value = prefs.getString("alarmSound") ?? "기본음 (Bell)";
  globalBgmEnabled.value = prefs.getBool("bgmEnabled") ?? false;
  globalBgmTrack.value = prefs.getString("bgmTrack") ?? "백색소음 (White Noise)";
}

void initSettingsListener() {
  globalBgColor.addListener(saveSettings);
  globalClockColor.addListener(saveSettings);
  globalDigitalColor.addListener(saveSettings);
  globalIndicatorColor.addListener(saveSettings);
  globalBgVideoName.addListener(saveSettings);

  globalIsTimerMode.addListener(saveSettings);
  globalDisplayMode.addListener(saveSettings);
  globalIndicatorMode.addListener(saveSettings);
  globalDigitalStyle.addListener(saveSettings);
  globalDigitalFontSize.addListener(saveSettings);
  globalHapticIntensity.addListener(saveSettings);

  globalTimerMaxString.addListener(() {
    saveSettings();
    String val = globalTimerMaxString.value;
    if (val.contains("30초")) globalTimerMaxSeconds.value = 30.0;
    else if (val.contains("60초")) globalTimerMaxSeconds.value = 60.0;
    else if (val.contains("120초")) globalTimerMaxSeconds.value = 120.0;
    else if (val.contains("30분")) globalTimerMaxSeconds.value = 1800.0;
    else if (val.contains("60분")) globalTimerMaxSeconds.value = 3600.0;
    else if (val.contains("120분")) globalTimerMaxSeconds.value = 7200.0;
  });

  globalAlarmEnabled.addListener(saveSettings);
  globalAlarmSound.addListener(saveSettings);
  globalBgmEnabled.addListener(saveSettings);
  globalBgmTrack.addListener(saveSettings);
}

class GlobalBgmManager {
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  static bool _isInitialized = false;

  static void init() {
    if (_isInitialized) return;
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    globalBgmEnabled.addListener(_updateBgm);
    globalBgmTrack.addListener(_updateBgm);
    _isInitialized = true;
    _updateBgm();
  }

  static Future<void> _updateBgm() async {
    if (globalBgmEnabled.value) {
      String option = globalBgmTrack.value;
      String fileName = "";
      if (option == "백색소음") fileName = "white_noise.mp3";
      else if (option == "잔잔한 비") fileName = "rain.mp3";
      else if (option == "모닥불") fileName = "fireplace.mp3";
      else if (option == "카페 소음") fileName = "cafe.mp3";

      if (fileName.isNotEmpty) {
        try {
          await _bgmPlayer.play(AssetSource('audio/$fileName'));
        } catch (e) {
          debugPrint("BGM 재생 실패: $e");
        }
      }
    } else {
      await _bgmPlayer.stop();
    }
  }
}

class DragHapticManager {
  static int _lastTick = -1;
  static void checkAndTrigger(int currentTick) {
    if (_lastTick != currentTick) {
      _lastTick = currentTick;
      String intensity = globalHapticIntensity.value.toUpperCase();
      if (intensity == "NONE") return;
      if (intensity == "SOFT") HapticFeedback.heavyImpact(); 
      else if (intensity == "MEDIUM") HapticFeedback.mediumImpact(); 
      else if (intensity == "STRONG") HapticFeedback.lightImpact(); 
    }
  }
}

class FloatingGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const FloatingGlassContainer({super.key, required this.child, this.padding = const EdgeInsets.all(5)});
  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, elevation: 0, borderRadius: BorderRadius.circular(20.0), clipBehavior: Clip.antiAlias, child: Padding(padding: padding, child: child));
  }
}

class FloatingGlassMenuButton extends StatelessWidget {
  final Color backgroundColor;
  FloatingGlassMenuButton({super.key, required this.backgroundColor});
  final GlobalKey _buttonKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    Color iconColor = backgroundColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(top: screenHeight * 0.00, left: screenWidth * 0.00),
        child: FloatingGlassContainer(
          padding: EdgeInsets.zero,
          child: IconButton(
            key: _buttonKey, padding: EdgeInsets.all(screenWidth * 0.02), constraints: const BoxConstraints(),
            icon: Icon(Icons.more_horiz, size: screenWidth * 0.04, color: iconColor),
            onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())); },
          ),
        ),
      ),
    );
  }
}

class SharedClockPainter extends CustomPainter {
  final double drawnSeconds; final double maxScaleSeconds; final bool isTimer; final String indicatorMode;
  SharedClockPainter(this.drawnSeconds, this.maxScaleSeconds, {this.isTimer = true, this.indicatorMode = "number"});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.5;

    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);
    canvas.drawCircle(center + const Offset(4, 4), radius, shadowPaint);

    final facePaint = Paint()..color = globalBgColor.value;
    canvas.drawCircle(center, radius, facePaint);

    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.04)..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, highlightPaint);

    final rimPaint = Paint()..color = Colors.white.withOpacity(0.08)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, rimPaint);

    final sweepAngle = (drawnSeconds / maxScaleSeconds) * 2 * pi;
    double startAngle = isTimer ? -pi / 2 + ((maxScaleSeconds - drawnSeconds) / maxScaleSeconds) * 2 * pi : -pi / 2;

    final paintArc = Paint()..color = globalClockColor.value..style = PaintingStyle.fill;
    if (drawnSeconds > 0) { canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.98), startAngle, sweepAngle, true, paintArc); }

    final tickPaint = Paint()..color = globalIndicatorColor.value.withOpacity(0.4)..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    final fiveTickPaint = Paint()..color = globalIndicatorColor.value.withOpacity(0.8)..strokeWidth = 3.0..strokeCap = StrokeCap.round;

    for (int t = 0; t < 60; t++) {
      final angle = (t / 60) * 2 * pi - pi / 2; bool isFiveMinute = t % 5 == 0;
      Paint currentPaint = isFiveMinute ? fiveTickPaint : tickPaint; double innerRadiusRatio = isFiveMinute ? 0.92 : 0.96;
      canvas.drawLine(center + Offset(cos(angle) * (radius * innerRadiusRatio), sin(angle) * (radius * innerRadiusRatio)), center + Offset(cos(angle) * radius, sin(angle) * radius), currentPaint);
    }

    final double relativeFontSize = radius * 0.1;
    final double relativePadding = radius * 1.08;
    final textPainter = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);

    String indMode = indicatorMode.toLowerCase();
    double tickInterval = maxScaleSeconds / 12;

    for (int i = 0; i < 12; i++) {
      if (indMode == "none") continue;
      if (indMode == "max_only" && i != 0) continue; 

      double currentScale = i * tickInterval;
      double angle = isTimer ? (-pi / 2 - (i / 12) * 2 * pi) : (-pi / 2 + (i / 12) * 2 * pi);
      final x = center.dx + relativePadding * cos(angle); final y = center.dy + relativePadding * sin(angle);

      if (indMode == "dot") {
        final dotPaint = Paint()..color = globalIndicatorColor.value..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), radius * 0.03, dotPaint);
      } else if (indMode == "number" || indMode == "max_only") {
        String tickText;
        if (indMode == "max_only") {
          tickText = formatDigitalTimeLong(maxScaleSeconds);
        } else {
          double val = maxScaleSeconds <= 120 ? currentScale : currentScale / 60;
          tickText = (val.roundToDouble() == val || (val - val.roundToDouble()).abs() < 0.001) ? val.round().toString() : val.toStringAsFixed(1);
          if (currentScale == 0) {
            double maxVal = maxScaleSeconds <= 120 ? maxScaleSeconds : maxScaleSeconds / 60;
            tickText = (maxVal.roundToDouble() == maxVal || (maxVal - maxVal.roundToDouble()).abs() < 0.001) ? maxVal.round().toString() : maxVal.toStringAsFixed(1);
          }
        }
        textPainter.text = TextSpan(text: tickText, style: TextStyle(fontSize: relativeFontSize, color: globalIndicatorColor.value, fontWeight: FontWeight.bold));
        textPainter.layout(); textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
      }
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

String formatDigitalTimeLong(double seconds) {
  int s = seconds.toInt(); int m = s ~/ 60; s = s % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class CustomDigitalClock extends StatelessWidget {
  final double seconds; final String styleMode; final double fontSize; final Color defaultColor;
  const CustomDigitalClock({super.key, required this.seconds, required this.styleMode, required this.fontSize, this.defaultColor = Colors.redAccent});

  @override
  Widget build(BuildContext context) {
    String timeString = formatDigitalTimeLong(seconds);
    String style = styleMode.toLowerCase();

    if (style == "flip") {
      return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: timeString.split('').map((char) {
        if (char == ':') return Padding(padding: const EdgeInsets.symmetric(horizontal: 6.0), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: fontSize * 0.12, height: fontSize * 0.12, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(1.0))), SizedBox(height: fontSize * 0.25), Container(width: fontSize * 0.12, height: fontSize * 0.12, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(1.0))) ]));
        return ClassicFlipDigit(digit: char, fontSize: fontSize);
      }).toList());
    } else if (style == "segment") {
      return Row(mainAxisSize: MainAxisSize.min, children: timeString.split('').map((char) => Padding(padding: const EdgeInsets.symmetric(horizontal: 3.0), child: SevenSegmentDigit(digit: char, height: fontSize * 0.9, color: defaultColor))).toList());
    } else {
      return Text(timeString, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: defaultColor));
    }
  }
}

class ClassicFlipDigit extends StatefulWidget {
  final String digit; final double fontSize; const ClassicFlipDigit({super.key, required this.digit, required this.fontSize});
  @override State<ClassicFlipDigit> createState() => _ClassicFlipDigitState();
}
class _ClassicFlipDigitState extends State<ClassicFlipDigit> with SingleTickerProviderStateMixin {
  late String _currentDigit, _nextDigit; late AnimationController _controller; late Animation<double> _animation;
  @override void initState() { super.initState(); _currentDigit = widget.digit; _nextDigit = widget.digit; _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250)); _animation = Tween<double>(begin: 0, end: 1).animate(_controller)..addStatusListener((status) { if (status == AnimationStatus.completed) setState(() => _currentDigit = _nextDigit); }); }
  @override void didUpdateWidget(ClassicFlipDigit oldWidget) { super.didUpdateWidget(oldWidget); if (widget.digit != oldWidget.digit) { _nextDigit = widget.digit; _controller.forward(from: 0.0); } }
  Widget _buildHalf(String digit, bool isTop) => ClipRect(child: Align(alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter, heightFactor: 0.5, child: Container(width: widget.fontSize * 0.85, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0), decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.vertical(top: isTop ? const Radius.circular(8.0) : Radius.zero, bottom: isTop ? Radius.zero : const Radius.circular(8.0))), child: Text(digit, style: TextStyle(fontSize: widget.fontSize, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)))));
  @override Widget build(BuildContext context) { return AnimatedBuilder(animation: _animation, builder: (context, child) { final isFirstHalf = _animation.value < 0.5; Widget topHalf, bottomHalf; if (isFirstHalf) { final flipValue = _animation.value * 2; topHalf = Stack(children: [_buildHalf(_nextDigit, true), Transform(transform: Matrix4.identity()..setEntry(3, 2, 0.003)..rotateX(-flipValue * (pi / 2)), alignment: Alignment.bottomCenter, child: _buildHalf(_currentDigit, true))]); bottomHalf = _buildHalf(_currentDigit, false); } else { final flipValue = (_animation.value - 0.5) * 2; topHalf = _buildHalf(_nextDigit, true); bottomHalf = Stack(children: [_buildHalf(_currentDigit, false), Transform(transform: Matrix4.identity()..setEntry(3, 2, 0.003)..rotateX((1.0 - flipValue) * (pi / 2)), alignment: Alignment.topCenter, child: _buildHalf(_nextDigit, false))]); } return Container(margin: const EdgeInsets.symmetric(horizontal: 2.0), decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]), child: Column(mainAxisSize: MainAxisSize.min, children: [topHalf, Container(height: 2.0, width: widget.fontSize * 0.7, color: Colors.black87), bottomHalf])); }); }
}

class SevenSegmentDigit extends StatelessWidget {
  final String digit; final double height; final Color color; const SevenSegmentDigit({super.key, required this.digit, required this.height, required this.color});
  @override Widget build(BuildContext context) {
    if (digit == ':') return Transform(transform: Matrix4.skewX(-0.15), child: SizedBox(width: height * 0.25, height: height, child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Container(width: height * 0.1, height: height * 0.1, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1.5))), Container(width: height * 0.1, height: height * 0.1, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1.5)))])));
    final bool a = ['0', '2', '3', '5', '6', '7', '8', '9'].contains(digit); final bool b = ['0', '1', '2', '3', '4', '7', '8', '9'].contains(digit); final bool c = ['0', '1', '3', '4', '5', '6', '7', '8', '9'].contains(digit); final bool d = ['0', '2', '3', '5', '6', '8', '9'].contains(digit); final bool e = ['0', '2', '6', '8'].contains(digit); final bool f = ['0', '4', '5', '6', '8', '9'].contains(digit); final bool g = ['2', '3', '4', '5', '6', '8', '9'].contains(digit);
    double w = height * 0.55; double t = height * 0.18; double gap = height * 0.05; Widget segment(bool active) => Container(margin: EdgeInsets.all(gap), decoration: BoxDecoration(color: active ? color : color.withOpacity(0.08), borderRadius: BorderRadius.circular(t / 2)));
    return Transform(transform: Matrix4.skewX(-0.15), child: SizedBox(width: w, height: height, child: Stack(children: [Positioned(top: 0, left: t * 0.4, right: t * 0.4, height: t, child: segment(a)), Positioned(top: t * 0.5, right: 0, width: t, height: height / 2 - t * 0.5, child: segment(b)), Positioned(bottom: t * 0.5, right: 0, width: t, height: height / 2 - t * 0.5, child: segment(c)), Positioned(bottom: 0, left: t * 0.4, right: t * 0.4, height: t, child: segment(d)), Positioned(bottom: t * 0.5, left: 0, width: t, height: height / 2 - t * 0.5, child: segment(e)), Positioned(top: t * 0.5, left: 0, width: t, height: height / 2 - t * 0.5, child: segment(f)), Positioned(top: height / 2 - t / 2, left: t * 0.4, right: t * 0.4, height: t, child: segment(g))])));
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
  final VoidCallback? onDigitalLongPress;

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
    this.indicatorModeOverride,
    this.onDigitalLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // 🌟 1. 가로 모드인지 세로 모드인지 감지합니다!
        final bool isLandscape = availableWidth > availableHeight;

        // =========================================================
        // 🌟 2. [추가됨] 아날로그 시계 크기 커스텀 (여기 숫자를 바꿔서 조절하세요!)
        // =========================================================
        double clockSize;
        if (isLandscape) {
          // 💡 가로 모드일 때 아날로그 시계 크기: 높이(availableHeight)의 85% 
          // (더 키우고 싶으면 0.9, 줄이고 싶으면 0.7 등으로 변경하세요)
          clockSize = availableHeight * 0.75; 
        } else {
          // 💡 세로 모드일 때 아날로그 시계 크기: 너비(availableWidth)의 75%
          // (더 꽉 차게 하고 싶으면 0.85, 줄이고 싶으면 0.65 등으로 변경하세요)
          clockSize = availableWidth * 0.65; 
        }

        return AnimatedBuilder(
          animation: Listenable.merge([
            globalDisplayMode,
            globalIndicatorMode,
            globalDigitalStyle,
            globalClockColor,
            globalDigitalColor,
            globalIndicatorColor,
            globalDigitalFontSize,
          ]),
          builder: (context, child) {
            String displayMode = globalDisplayMode.value.toLowerCase();
            String indicatorMode = indicatorModeOverride ?? globalIndicatorMode.value.toLowerCase();
            String digitalStyle = globalDigitalStyle.value.toLowerCase();
            String fontSizeStr = globalDigitalFontSize.value.toLowerCase();

            // =========================================================
            // 🌟 3. 디지털 시계 크기 커스텀 (여기 숫자도 자유롭게 조절!)
            // =========================================================
            double baseFontSize = availableHeight * 0.07; // 기본 크기

            if (displayMode == "digital") {
              if (isLandscape) {
                // 💡 가로 화면 + 디지털 ONLY : 글자를 엄청 크게! (높이의 35%)
                baseFontSize = availableHeight * 0.35; 
              } else {
                // 💡 세로 화면 + 디지털 ONLY : 기본보다 크게! (높이의 15%)
                baseFontSize = availableHeight * 0.15; 
              }
            } else if (displayMode == "both"){
              if (isLandscape){
              // 💡 가로 화면 + BOTH 모드 : 아날로그 시계 옆에 있으니 살짝 키움! (높이의 15%)
              baseFontSize = availableHeight * 0.15; 
              } else {
                baseFontSize = availableHeight * 0.08; 
              }
            }

            // 설정창(SMALL, MEDIUM, LARGE) 비율 적용
            double fontMultiplier = 1.0;
            if (fontSizeStr == "small") fontMultiplier = 0.7;
            if (fontSizeStr == "large") fontMultiplier = 1.3;
            
            final digitalFontSize = baseFontSize * fontMultiplier;

            // =========================================================
            // 🌟 아날로그 시계 위젯 조립
            // =========================================================
            Widget analogClockWidget = GestureDetector(
              onPanStart: onPanStart != null ? (_) => onPanStart!() : null,
              onPanUpdate: onPanUpdate != null
                  ? (details) {
                      final center = Offset(clockSize / 2, clockSize / 2);
                      double angle = atan2(
                        details.localPosition.dy - center.dy,
                        details.localPosition.dx - center.dx,
                      );
                      double clockwise = angle - (-pi / 2);
                      if (clockwise < 0) clockwise += 2 * pi;

                      int currentTick = ((clockwise / (2 * pi)) * 60).toInt();
                      DragHapticManager.checkAndTrigger(currentTick);

                      onPanUpdate!(details.localPosition, Size(clockSize, clockSize));
                    }
                  : null,
              onPanEnd: onPanEnd != null ? (_) => onPanEnd!() : null,
              child: CustomPaint(
                size: Size(clockSize, clockSize),
                painter: SharedClockPainter(
                  drawnSeconds, maxScaleSeconds,
                  isTimer: isTimer, indicatorMode: indicatorMode,
                ),
              ),
            );

            // =========================================================
            // 🌟 디지털 시계 위젯 조립
            // =========================================================
            Widget digitalClockWidget = GestureDetector(
              onLongPress: onDigitalLongPress,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: CustomDigitalClock(
                  seconds: digitalSeconds,
                  styleMode: digitalStyle,
                  fontSize: digitalFontSize,
                  defaultColor: globalDigitalColor.value,
                ),
              ),
            );

            // =========================================================
            // 🌟 4. 화면 배치 로직 (가로 모드면 좌우, 세로 모드면 상하)
            // =========================================================
            Widget layoutContent;

            if (displayMode == "digital") {
              // 디지털 ONLY는 항상 정중앙
              layoutContent = Center(child: digitalClockWidget);
            } else if (displayMode == "analog") {
              // 아날로그 ONLY는 항상 정중앙
              layoutContent = Center(child: analogClockWidget);
            } else {
              // 💡 BOTH 모드일 때 가로/세로 배치 분기!
              if (isLandscape) {
                // 가로 모드: 좌측 아날로그, 우측 디지털
                layoutContent = Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    analogClockWidget,
                    digitalClockWidget,
                  ],
                );
              } else {
                // 세로 모드: 상단 아날로그, 하단 디지털
                layoutContent = Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    analogClockWidget,
                    SizedBox(height: availableHeight * 0.08),
                    digitalClockWidget,
                  ],
                );
              }
            }

            return GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: onTapToggle,
              child: SizedBox(
                width: availableWidth,
                height: availableHeight,
                child: layoutContent,
              ),
            );
          },
        );
      },
    );
  }
}

// =========================================================
// 🌟 동영상뿐만 아니라 '사진' 배경까지 완벽 지원하는 배경 위젯!
// =========================================================
class GlobalVideoBackground extends StatefulWidget {
  final Widget child; 
  const GlobalVideoBackground({super.key, required this.child});

  @override
  State<GlobalVideoBackground> createState() => _GlobalVideoBackgroundState();
}

class _GlobalVideoBackgroundState extends State<GlobalVideoBackground> {
  VideoPlayerController? _videoController;
  bool _hasError = false;
  
  // 💡 현재 띄워진 배경의 경로와 '영상인지 사진인지' 구분하는 변수 추가!
  String _currentBgPath = ""; 
  bool _isCurrentVideo = false; 

  @override
  void initState() {
    super.initState();
    globalBgVideoName.addListener(_updateVideoState);
    _updateVideoState();
  }

  void _updateVideoState() {
    // 1. "사용 안 함"이면 싹 다 끄고 비우기
    if (globalBgVideoName.value == "사용 안 함") {
      _videoController?.dispose();
      _videoController = null;
      _currentBgPath = "";
      _isCurrentVideo = false;
      if (mounted) setState(() {});
      return;
    }

    // 2. 💡 [핵심] 이름표를 보고 파일 경로와 '동영상 여부'를 짝지어줍니다!
    String targetPath = "";
    bool isVideo = false;

    if (globalBgVideoName.value == "비 오는 밤 (Rain)") {
      targetPath = 'assets/video/rainwindow.mp4';
      isVideo = true; // 이건 동영상이야!
    } 
    // 🔥 나중에 사진을 추가하고 싶다면 이런 식으로 계속 적어주시면 됩니다!
    // else if (globalBgVideoName.value == "멋진 우주 사진") {
    //   targetPath = 'assets/images/space.jpg';
    //   isVideo = false; // 이건 사진이야!
    // }

    // 3. 배경이 바뀌었을 때만 새로 로딩합니다.
    if (_currentBgPath != targetPath) {
      _currentBgPath = targetPath;
      _isCurrentVideo = isVideo;

      if (isVideo) {
        // 🎬 동영상일 경우: 비디오 플레이어 가동!
        _videoController?.dispose();
        _hasError = false;
        
        _videoController = VideoPlayerController.asset(targetPath)
          ..initialize().then((_) {
            _videoController!.setVolume(0.0); 
            _videoController!.setLooping(true); 
            _videoController!.play(); 
            if (mounted) setState(() {});
          }).catchError((e) {
            debugPrint("비디오 재생 에러: $e");
            if (mounted) setState(() => _hasError = true);
          });
      } else {
        // 🖼️ 사진일 경우: 비디오 플레이어는 필요 없으니 끕니다!
        _videoController?.dispose();
        _videoController = null;
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    globalBgVideoName.removeListener(_updateVideoState);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 기본 배경색 깔기
        ValueListenableBuilder<Color>(
          valueListenable: globalBgColor,
          builder: (context, bgColor, child) {
            return Container(color: bgColor);
          }
        ),
        
        // 2-A. 만약 '동영상'이고 로딩이 끝났다면 꽉 차게 틀어주기
        if (_isCurrentVideo && _videoController != null && _videoController!.value.isInitialized && !_hasError)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),

        // 2-B. 💡 만약 '사진'이라면 Image 위젯으로 꽉 차게 띄워주기!
        if (!_isCurrentVideo && _currentBgPath.isNotEmpty)
          Positioned.fill(
            child: Image.asset(
              _currentBgPath,
              fit: BoxFit.cover, // 사진 비율 안 깨지고 화면에 꽉 차게!
            ),
          ),
          
        // 3. 그 위에 진짜 앱 화면 올리기
        widget.child,
      ],
    );
  }
}
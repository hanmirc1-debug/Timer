import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import '../services/firebase_settings_service.dart';
import 'package:vibration/vibration.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

// shared_design.dart 파일 내부에 추가

// 뽀모도로 활성화 여부
ValueNotifier<bool> globalPomodoroMode = ValueNotifier<bool>(false);

// 뽀모도로 시간 및 사이클 설정
ValueNotifier<String> globalPomodoroWorkTime = ValueNotifier<String>("25분");
ValueNotifier<String> globalPomodoroShortBreak = ValueNotifier<String>("5분");
ValueNotifier<String> globalPomodoroLongBreak = ValueNotifier<String>("15분");
ValueNotifier<String> globalPomodoroCycleCount = ValueNotifier<String>("4번");
ValueNotifier<String> globalPomodoroMaxSessions = ValueNotifier<String>(
  "제한 없음",
);
ValueNotifier<bool> globalIsTutorialActive = ValueNotifier(false); // 🔥 튜토리얼 진행 여부
// 뽀모도로 자동 시작 설정
ValueNotifier<bool> globalPomodoroAutoWork = ValueNotifier<bool>(
  false,
); // 집중 모드 자동 시작
ValueNotifier<bool> globalPomodoroAutoBreak = ValueNotifier<bool>(
  true,
); // 휴식 모드 자동 시작

// =========================================================
// 🌟 0. 앱 전체 공유 설정값
// =========================================================
final ValueNotifier<bool> globalIsTimerMode = ValueNotifier<bool>(true);
final ValueNotifier<String> globalDisplayMode = ValueNotifier<String>("BOTH");
final ValueNotifier<String> globalIndicatorMode = ValueNotifier<String>(
  "NUMBER",
);
final ValueNotifier<String> globalDigitalStyle = ValueNotifier<String>(
  "DEFAULT",
);
final ValueNotifier<String> globalDigitalFontSize = ValueNotifier<String>(
  "MEDIUM",
);
final ValueNotifier<String> globalHapticIntensity = ValueNotifier<String>(
  "MEDIUM",
);

final ValueNotifier<bool> globalAlarmEnabled = ValueNotifier<bool>(true);
final ValueNotifier<String> globalAlarmSound = ValueNotifier<String>(
  alarmOptions.first,
);
final ValueNotifier<bool> globalBgmEnabled = ValueNotifier<bool>(false);

final ValueNotifier<String> globalBgmTrack = ValueNotifier<String>(
  bgmOptions.first,
);

final ValueNotifier<String> globalTimerMaxString = ValueNotifier<String>(
  "60초 (1분)",
);
final ValueNotifier<double> globalTimerMaxSeconds = ValueNotifier<double>(60.0);

final ValueNotifier<String> globalBgVideoName = ValueNotifier<String>("사용 안 함");
// 🔥 이 줄을 추가하세요! (시계 이미지/영상용 변수)
ValueNotifier<String> globalClockVideoName = ValueNotifier("사용 안 함");

final ValueNotifier<Color> globalBgColor = ValueNotifier(
  const Color(0xFF252528),
);
final ValueNotifier<Color> globalClockColor = ValueNotifier(
  const Color.fromARGB(255, 185, 70, 70),
);
final ValueNotifier<Color> globalDigitalColor = ValueNotifier(
  const Color(0xFF8E8E93),
);
final ValueNotifier<Color> globalIndicatorColor = ValueNotifier(
  const Color(0xFF8E8E93),
);

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
  await prefs.setBool("vibrationEnabled", globalVibrationEnabled.value);
  await prefs.setBool("alarmEnabled", globalAlarmEnabled.value);
  await prefs.setString("alarmSound", globalAlarmSound.value);
  await prefs.setBool("bgmEnabled", globalBgmEnabled.value);
  await prefs.setString("bgmTrack", globalBgmTrack.value);
  await prefs.setBool("pomodoroMode", globalPomodoroMode.value);
  await prefs.setString("pomodoroWork", globalPomodoroWorkTime.value);
  await prefs.setString("pomodoroShortBreak", globalPomodoroShortBreak.value);
  await prefs.setString("pomodoroLongBreak", globalPomodoroLongBreak.value);
  await prefs.setString("pomodoroCycle", globalPomodoroCycleCount.value);
  await prefs.setString("pomodoroMax", globalPomodoroMaxSessions.value);
  await prefs.setBool("pomodoroAutoWork", globalPomodoroAutoWork.value);
  await prefs.setBool("pomodoroAutoBreak", globalPomodoroAutoBreak.value);
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
  globalVibrationEnabled.value = prefs.getBool("vibrationEnabled") ?? true;
  globalBgColor.value = Color(prefs.getInt("bgColor") ?? 0xFF252528);
  globalClockColor.value = Color(prefs.getInt("clockColor") ?? 0xFFB94646);
  globalDigitalColor.value = Color(prefs.getInt("digitalColor") ?? 0xFF8E8E93);
  globalIndicatorColor.value = Color(
    prefs.getInt("indicatorColor") ?? 0xFF8E8E93,
  );

  globalAlarmEnabled.value = prefs.getBool("alarmEnabled") ?? true;
  globalAlarmSound.value = prefs.getString("alarmSound") ?? alarmOptions.first;
  globalBgmEnabled.value = prefs.getBool("bgmEnabled") ?? false;
  globalBgmTrack.value = prefs.getString("bgmTrack") ?? bgmOptions.first;
  globalPomodoroMode.value = prefs.getBool("pomodoroMode") ?? false;
  globalPomodoroWorkTime.value = prefs.getString("pomodoroWork") ?? "25분";

  globalPomodoroShortBreak.value =
      prefs.getString("pomodoroShortBreak") ?? "5분";
  globalPomodoroLongBreak.value = prefs.getString("pomodoroLongBreak") ?? "15분";
  globalPomodoroCycleCount.value = prefs.getString("pomodoroCycle") ?? "4번";
  globalPomodoroMaxSessions.value = prefs.getString("pomodoroMax") ?? "제한 없음";
  globalPomodoroAutoWork.value = prefs.getBool("pomodoroAutoWork") ?? false;
  globalPomodoroAutoBreak.value = prefs.getBool("pomodoroAutoBreak") ?? true;
}

void initSettingsListener() {
  bool _lastVibrationState = globalVibrationEnabled.value;
  globalVibrationEnabled.addListener(() {
    // 🔥 OFF → ON 바뀌는 순간만 진동
    Vibration.vibrate(duration: 80, amplitude: 255);

    _lastVibrationState = globalVibrationEnabled.value;

    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
  globalBgColor.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
  globalClockColor.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
  globalDigitalColor.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
  globalIndicatorColor.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
  globalBgVideoName.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });

  globalIsTimerMode.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
  globalDisplayMode.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
  globalIndicatorMode.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
  globalDigitalStyle.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
  globalDigitalFontSize.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
  globalHapticIntensity.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });

  globalTimerMaxString.addListener(() {
    saveSettings();
    String val = globalTimerMaxString.value;
    if (val.contains("30초"))
      globalTimerMaxSeconds.value = 30.0;
    else if (val.contains("60초"))
      globalTimerMaxSeconds.value = 60.0;
    else if (val.contains("120초"))
      globalTimerMaxSeconds.value = 120.0;
    else if (val.contains("30분"))
      globalTimerMaxSeconds.value = 1800.0;
    else if (val.contains("60분"))
      globalTimerMaxSeconds.value = 3600.0;
    else if (val.contains("120분"))
      globalTimerMaxSeconds.value = 7200.0;
  });

  globalAlarmEnabled.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
  globalAlarmSound.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
  globalBgmEnabled.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
  globalBgmTrack.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
  globalPomodoroMode.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });

  globalPomodoroWorkTime.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });

  globalPomodoroShortBreak.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });

  globalPomodoroLongBreak.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });

  globalPomodoroCycleCount.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });

  globalPomodoroMaxSessions.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });

  globalPomodoroAutoWork.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });

  globalPomodoroAutoBreak.addListener(() {
    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  });
}

final ValueNotifier<bool> globalVibrationEnabled = ValueNotifier<bool>(true);

const Map<String, String> alarmSoundMap = {
  "기본음1": "audio/alarm/default2.mp3",
  "기본음2": "audio/alarm/default.mp3",
  "자전거 벨": "audio/alarm/bike.mp3",
  "빠른 알림 1": "audio/alarm/fast1.mp3",
  "빠른 알림 2": "audio/alarm/fast2.mp3",
  "신비로운 1": "audio/alarm/mystical1.mp3",
  "신비로운 2": "audio/alarm/mystical2.mp3",
  "신비로운 3": "audio/alarm/mystical3.mp3",
  "심플한 알림 1": "audio/alarm/simple1.mp3",
  "심플한 알림 2": "audio/alarm/simple2.mp3",
  "심플한 알림 3": "audio/alarm/simple3.mp3",
  "심플한 알림 4": "audio/alarm/simple4.mp3",
};
final List<String> alarmOptions = [...alarmSoundMap.keys];

String getAlarmPath(String name) {
  return alarmSoundMap[name] ?? "audio/alarm/default2.mp3";
}

const Map<String, String> bgmMap = {
  "봄": "audio/bgm/spring.mp3",
  "강한 빗소리": "audio/bgm/rain.mp3",
  "빗소리": "audio/bgm/soft_rain.mp3",
  "피아노1": "audio/bgm/piano1.mp3",
  "피아노2": "audio/bgm/piano2.mp3",
};
final List<String> bgmOptions = [...bgmMap.keys];

class GlobalBgmManager {
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  static final AudioPlayer _alarmPlayer = AudioPlayer(); // 🔥 분리

  static bool _isInitialized = false;

  static void init() {
    if (_isInitialized) return;

    _bgmPlayer.setReleaseMode(ReleaseMode.loop);

    globalBgmEnabled.addListener(_updateBgm);
    globalBgmTrack.addListener(_updateBgm);

    _isInitialized = true;
    _updateBgm();
  }

  // 🔥 전체 정지
  static Future<void> stopAllSound() async {
    await _bgmPlayer.stop();
    await _alarmPlayer.stop();
  }

  // 🔥 BGM 재생
  static Future<void> playBgm(String name) async {
    debugPrint("🔥 playBgm CALLED");
    final path = bgmMap[name];
    if (path == null) return;

    await _bgmPlayer.stop();
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(AssetSource(path));
  }

  static Future<void> stopBgm() async {
    await _bgmPlayer.stop();
  }

  // 🔥 알람 재생 (핵심)
  static Future<void> playAlarmSound(String soundName) async {
    debugPrint("🔥 playAlarmSound CALLED");
    // 🔥 진동 추가
    if (globalVibrationEnabled.value) {
      Vibration.vibrate(pattern: [0, 500, 200, 500], amplitude: 255);
    }

    final path = alarmSoundMap[soundName];
    if (path == null) return;

    await _alarmPlayer.stop();
    await _alarmPlayer.setReleaseMode(ReleaseMode.loop); // 🔥 핵심
    await _alarmPlayer.play(AssetSource(path));
  }

  // 🔥 알람 미리듣기 (설정페이지용)
  static Future<void> previewAlarmSound(String soundName) async {
    debugPrint("🔥 previewAlarmSound CALLED");
    final path = alarmSoundMap[soundName] ?? "audio/alarm/default2.mp3";

    await _alarmPlayer.stop();
    await _alarmPlayer.play(AssetSource(path));
  }

  // 🔥 BGM 미리듣기 (설정페이지용)
  static Future<void> previewBgm(String soundName) async {
    debugPrint("🔥 previewBgm CALLED");
    final path = bgmMap[soundName] ?? "audio/bgm/spring.mp3";

    await _bgmPlayer.stop();
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(AssetSource(path));
  }

  // 🔥 BGM 자동 업데이트
  static Future<void> _updateBgm() async {
    if (globalBgmEnabled.value) {
      String option = globalBgmTrack.value;

      final path = bgmMap[option]; // 🔥 map 사용

      if (path != null) {
        try {
          await _bgmPlayer.stop(); // 🔥 추가 (중복 방지)
          await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
          await _bgmPlayer.play(AssetSource(path));
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

      // 🔥 핵심 수정 1: 웹(Chrome)으로 실행 중일 때는 진동 명령을 아예 스킵합니다!
      if (kIsWeb) return;

      // 🔥 핵심 수정 2: 모바일에서도 혹시 모를 진동 에러로 앱이 멈추는 것을 방지합니다.
      try {
        if (intensity == "SOFT") {
          Vibration.vibrate(duration: 20, amplitude: 80);
        } else if (intensity == "MEDIUM") {
          Vibration.vibrate(duration: 30, amplitude: 160);
        } else if (intensity == "STRONG") {
          Vibration.vibrate(duration: 40, amplitude: 255);
        }
      } catch (e) {
        debugPrint("진동 호출 실패 (무시됨): $e");
      }
    }
  }
}

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

class FloatingGlassMenuButton extends StatelessWidget {
  final Color backgroundColor;
  FloatingGlassMenuButton({super.key, required this.backgroundColor});
  final GlobalKey _buttonKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isLandscape = screenWidth > screenHeight;
    final base = isLandscape ? screenHeight : screenWidth;
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
            padding: EdgeInsets.all(screenHeight * 0.02),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(
              Icons.more_horiz,
              size: isLandscape
                  ? base *
                        0.05 // 🔥 가로모드 작게
                  : base * 0.07, // 🔥 세로모드 유지
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

if (globalClockColor.value != Colors.transparent && globalClockVideoName.value == "사용 안 함") {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);
      canvas.drawCircle(center + const Offset(4, 4), radius, shadowPaint);

// 🔥 [핵심 수정] BgColor(배경색) -> ClockColor(시계색) 으로 변경!
      //final facePaint = Paint()..color = globalClockColor.value; 
      //canvas.drawCircle(center, radius, facePaint);
    }

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, highlightPaint);

    final rimColor = globalClockColor.value == Colors.transparent
        ? globalIndicatorColor.value.withOpacity(0.4)
        : Colors.white.withOpacity(0.08);

    final rimPaint = Paint()
      ..color = rimColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = globalClockColor.value == Colors.transparent ? 2.0 : 1.0;
    canvas.drawCircle(center, radius, rimPaint);

    final sweepAngle = (drawnSeconds / maxScaleSeconds) * 2 * pi;
    double startAngle = isTimer
        ? -pi / 2 +
              ((maxScaleSeconds - drawnSeconds) / maxScaleSeconds) * 2 * pi
        : -pi / 2;

    Color arcColor = globalClockColor.value;
    if (globalClockColor.value == Colors.transparent) {
      arcColor = globalIndicatorColor.value.withOpacity(0.25);
    }

    final paintArc = Paint()
      ..color = arcColor
      ..style = PaintingStyle.fill;
if (drawnSeconds > 0 && globalClockVideoName.value == "사용 안 함") {
        canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.98),
        startAngle,
        sweepAngle,
        true,
        paintArc,
      );
    }

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

    String indMode = indicatorMode.toLowerCase();
    double tickInterval = maxScaleSeconds / 12;

    for (int i = 0; i < 12; i++) {
      if (indMode == "none") continue;
      if (indMode == "max_only" && i != 0) continue;

      double currentScale = i * tickInterval;
      double angle = isTimer
          ? (-pi / 2 - (i / 12) * 2 * pi)
          : (-pi / 2 + (i / 12) * 2 * pi);
      final x = center.dx + relativePadding * cos(angle);
      final y = center.dy + relativePadding * sin(angle);

      if (indMode == "dot") {
        final dotPaint = Paint()
          ..color = globalIndicatorColor.value
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), radius * 0.03, dotPaint);
      } else if (indMode == "number" || indMode == "max_only") {
        String tickText;
        if (indMode == "max_only") {
          tickText = formatDigitalTimeLong(maxScaleSeconds);
        } else {
          double val = maxScaleSeconds <= 120
              ? currentScale
              : currentScale / 60;
          tickText =
              (val.roundToDouble() == val ||
                  (val - val.roundToDouble()).abs() < 0.001)
              ? val.round().toString()
              : val.toStringAsFixed(1);
          if (currentScale == 0) {
            double maxVal = maxScaleSeconds <= 120
                ? maxScaleSeconds
                : maxScaleSeconds / 60;
            tickText =
                (maxVal.roundToDouble() == maxVal ||
                    (maxVal - maxVal.roundToDouble()).abs() < 0.001)
                ? maxVal.round().toString()
                : maxVal.toStringAsFixed(1);
          }
        }
        textPainter.text = TextSpan(
          text: tickText,
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
  int m = s ~/ 60;
  s = s % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

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
    String style = styleMode.toLowerCase();

    if (style == "flip") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: timeString.split('').map((char) {
          if (char == ':')
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
          return ClassicFlipDigit(digit: char, fontSize: fontSize);
        }).toList(),
      );
    } else if (style == "segment") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: timeString
            .split('')
            .map(
              (char) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: SevenSegmentDigit(
                  digit: char,
                  height: fontSize * 0.9,
                  color: defaultColor,
                ),
              ),
            )
            .toList(),
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

  Widget _buildHalf(String digit, bool isTop) => ClipRect(
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
    if (digit == ':')
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
    Widget segment(bool active) => Container(
      margin: EdgeInsets.all(gap),
      decoration: BoxDecoration(
        color: active ? color : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(t / 2),
      ),
    );
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

final GlobalKey analogClockHitKey = GlobalKey();
final GlobalKey digitalClockHitKey = GlobalKey();

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

        final bool isLandscape = availableWidth > availableHeight;

        double clockSize;
        if (isLandscape) {
          clockSize = availableHeight * 0.75;
        } else {
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
            globalClockVideoName, // 🔥 [핵심 추가] 시계 사진 변화를 감지하도록 추가
          ]),
          builder: (context, child) {
            String displayMode = globalDisplayMode.value.toLowerCase();
            String indicatorMode =
                indicatorModeOverride ??
                globalIndicatorMode.value.toLowerCase();
            String digitalStyle = globalDigitalStyle.value.toLowerCase();
            String fontSizeStr = globalDigitalFontSize.value.toLowerCase();

            double baseFontSize = availableHeight * 0.07;
            double fontMultiplier = 1.0;

            if (displayMode == "digital" || displayMode == "both") {
              if (displayMode == "digital") {
                baseFontSize = isLandscape
                    ? availableHeight * 0.35
                    : availableHeight * 0.15;
              } else if (displayMode == "both") {
                if (isLandscape) {
                  // 🔥 가로모드에서는 width 기준으로
                  baseFontSize = availableWidth * 0.12;
                } else {
                  baseFontSize = availableHeight * 0.12;
                }
              }

              if (digitalStyle == "flip" || digitalStyle == "segment") {
                if (fontSizeStr == "small") fontMultiplier = 0.5;
                if (fontSizeStr == "medium") fontMultiplier = 0.8;
                if (fontSizeStr == "large") fontMultiplier = 1.0;
              } else {
                if (fontSizeStr == "small") fontMultiplier = 0.7;
                if (fontSizeStr == "large") fontMultiplier = 1.3;
              }
            }
            final digitalFontSize = baseFontSize * fontMultiplier;
Widget analogClockWidget = GestureDetector(
              behavior: HitTestBehavior.opaque,
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

                      onPanUpdate!(
                        details.localPosition,
                        Size(clockSize, clockSize),
                      );
                    }
                  : null,
              onPanEnd: onPanEnd != null ? (_) => onPanEnd!() : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 🔥 1. 새롭게 추가된 부분: 부채꼴 모양에 맞춰 완벽하게 생기는 입체 그림자!
                  if (globalClockVideoName.value != "사용 안 함")
                    CustomPaint(
                      size: Size(clockSize, clockSize),
                      painter: PieShadowPainter(drawnSeconds, maxScaleSeconds, isTimer),
                    ),
// 🔥 핵심 1: 시간이 줄어듦에 따라 부채꼴 모양으로 잘려나가는 시계 사진!
                  if (globalClockVideoName.value != "사용 안 함")
                    ClipPath(
                      clipper: ClockImageClipper(drawnSeconds, maxScaleSeconds, isTimer),
                      child: Container(
                        width: clockSize,
                        height: clockSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: (globalClockVideoName.value == "노을 (Sunset)")
                                ? const AssetImage('assets/image/sunset.jpg')
                                : (globalClockVideoName.value == "밤하늘 (Sky Moon)")
                                    ? const AssetImage('assets/image/sky_moon.jpg')
                                    : (kIsWeb 
                                        ? NetworkImage(globalClockVideoName.value) as ImageProvider 
                                        : FileImage(File(globalClockVideoName.value))),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                  // 🔥 핵심 2: 터치 인식을 유지하면서 그 위에 눈금/숫자를 그리는 투명 CustomPaint
                  Container(
                    width: clockSize,
                    height: clockSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent, 
                    ),
                    child: CustomPaint(
                      key: analogClockHitKey,
                      size: Size(clockSize, clockSize),
                      painter: SharedClockPainter(
                        drawnSeconds,
                        maxScaleSeconds,
                        isTimer: isTimer,
                        indicatorMode: indicatorMode,
                      ),
                    ),
                  ),
                ],
              ),
            );

            Widget digitalClockWidget = GestureDetector(
              onLongPress: onDigitalLongPress,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  key: digitalClockHitKey,
                  color: Colors.transparent,
                  child: CustomDigitalClock(
                    seconds: digitalSeconds,
                    styleMode: digitalStyle,
                    fontSize: digitalFontSize,
                    defaultColor: globalDigitalColor.value,
                  ),
                ),
              ),
            );

            Widget layoutContent;

            if (displayMode == "digital") {
              layoutContent = Center(child: digitalClockWidget);
            } else if (displayMode == "analog") {
              layoutContent = Center(child: analogClockWidget);
            } else {
              if (isLandscape) {
                layoutContent = Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: Center(child: analogClockWidget)),
                    Expanded(flex: 5, child: Center(child: digitalClockWidget)),
                  ],
                );
              } else {
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
              //behavior: HitTestBehavior.deferToChild,
              behavior: HitTestBehavior.translucent, // 🔥 핵심 수정: 시계 빈 공간을 터치해도 무시되지 않고 정상 작동하게 만듦
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
// 🌸 1. 벚꽃잎 데이터 모델
// =========================================================
class CherryBlossomPetal {
  double x;
  double y;
  double speed;
  double spin;
  double angle;
  double scale;

  CherryBlossomPetal({
    required this.x,
    required this.y,
    required this.speed,
    required this.spin,
    required this.angle,
    required this.scale,
  });
}

// =========================================================
// 🌸 2. 벚꽃 애니메이션 오버레이 (바람에 흩날리는 효과)
// =========================================================
class CherryBlossomOverlay extends StatefulWidget {
  const CherryBlossomOverlay({super.key});

  @override
  State<CherryBlossomOverlay> createState() => _CherryBlossomOverlayState();
}

class _CherryBlossomOverlayState extends State<CherryBlossomOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<CherryBlossomPetal> _petals = [];
  final int _petalCount = 35; // 흩날리는 벚꽃잎 개수
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 화면 아무 곳이나 벚꽃잎 초기 배치
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      for (int i = 0; i < _petalCount; i++) {
        _petals.add(
          CherryBlossomPetal(
            x: _random.nextDouble() * size.width,
            y: _random.nextDouble() * size.height,
            speed: 1.0 + _random.nextDouble() * 2.0,
            spin: _random.nextDouble() * pi * 2,
            angle: _random.nextDouble() * 0.5,
            scale: 0.5 + _random.nextDouble() * 0.8,
          ),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: CherryBlossomPainter(_petals, _random),
          size: Size.infinite,
        );
      },
    );
  }
}

// =========================================================
// 🌸 3. 벚꽃잎 그리기 붓 (Painter)
// =========================================================
class CherryBlossomPainter extends CustomPainter {
  final List<CherryBlossomPetal> petals;
  final Random random;

  CherryBlossomPainter(this.petals, this.random);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB7C5)
          .withOpacity(0.8) // 예쁜 연분홍색
      ..style = PaintingStyle.fill;

    for (var petal in petals) {
      // 아래로, 그리고 살짝 대각선으로 떨어짐
      petal.y += petal.speed;
      petal.x += sin(petal.angle) * 1.5;
      petal.spin += 0.02; // 빙글빙글 돌기
      petal.angle += 0.01; // 바람에 흔들리기

      // 바닥으로 떨어지면 다시 위로 올려보냄
      if (petal.y > size.height + 20) {
        petal.y = -20;
        petal.x = random.nextDouble() * size.width;
      }
      if (petal.x > size.width + 20) petal.x = -20;
      if (petal.x < -20) petal.x = size.width + 20;

      // 벚꽃잎 모양 그려주기 (타원을 살짝 비틀어서 표현)
      canvas.save();
      canvas.translate(petal.x, petal.y);
      canvas.rotate(petal.spin);
      canvas.scale(petal.scale);
      canvas.drawOval(const Rect.fromLTWH(-5, -10, 10, 20), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =========================================================
// 🌟 동영상/사진 + 벚꽃 효과를 지원하는 완벽한 배경 위젯!
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
  String _currentBgPath = "";
  bool _isCurrentVideo = false;

  @override
  void initState() {
    super.initState();
    globalBgVideoName.addListener(_updateVideoState);
    _updateVideoState();
  }
// ---------------- ✨ 여기서부터 통째로 교체 ✨ ----------------
  void _updateVideoState() {
    String currentVal = globalBgVideoName.value;

    if (currentVal == "사용 안 함") {
      _videoController?.dispose();
      _videoController = null;
      _currentBgPath = "";
      _isCurrentVideo = false;
      if (mounted) setState(() {});
      return;
    }

    String targetPath = "";
    bool isVideo = false;

    // 1. 고정 프리셋 영상 확인
// 1. 고정 프리셋 영상 확인
    if (currentVal == "비 오는 밤 (Rain)") {
      targetPath = 'assets/video/rainwindow.mp4';
      isVideo = true;
    } else if (currentVal == "벚꽃 (Cherry Blossom)") {
      targetPath = 'assets/video/sakura.mp4';
      isVideo = true;
    } else if (currentVal == "노을 (Sunset)") {
      targetPath = 'assets/image/sunset.jpg'; // 🔥 노을 연결
      isVideo = false;
    } else if (currentVal == "밤하늘 (Sky Moon)") {
      targetPath = 'assets/image/sky_moon.jpg'; // 🔥 밤하늘 연결
      isVideo = false;
    }
    // 🌟 [핵심 추가] 프리셋이 아니면 사용자가 추가한 '사진/영상 경로'를 그대로 사용!
    else {
      targetPath = currentVal;
      // 파일명에 mp4가 들어있으면 비디오로 간주
      isVideo = currentVal.toLowerCase().contains(".mp4");
    }

    if (_currentBgPath != targetPath) {
      _currentBgPath = targetPath;
      _isCurrentVideo = isVideo;

      if (isVideo) {
        _videoController?.dispose();
        _hasError = false;
        
        // 에셋인지 로컬 파일인지 구분해서 로드
        if (targetPath.startsWith('assets/')) {
          _videoController = VideoPlayerController.asset(targetPath);
        } else {
          _videoController = VideoPlayerController.file(File(targetPath));
        }

        _videoController!.initialize().then((_) {
          _videoController!.setVolume(0.0);
          _videoController!.setLooping(true);
          _videoController!.play();
          if (mounted) setState(() {});
        }).catchError((e) {
          debugPrint("비디오 재생 에러: $e");
          if (mounted) setState(() => _hasError = true);
        });
      } else {
        _videoController?.dispose();
        _videoController = null;
        if (mounted) setState(() {});
      }
    }
  }
// ---------------- 여기까지 교체 끝 ----------------

  @override
  void dispose() {
    globalBgVideoName.removeListener(_updateVideoState);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 현재 "벚꽃" 테마가 켜져있는지 확인
    bool isCherryBlossom = globalBgVideoName.value.contains("벚꽃");

    return Stack(
      children: [
        ValueListenableBuilder<Color>(
          valueListenable: globalBgColor,
          builder: (context, bgColor, child) {
            return Container(color: bgColor);
          },
        ),

        if (_isCurrentVideo &&
            _videoController != null &&
            _videoController!.value.isInitialized &&
            !_hasError)
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

        if (!_isCurrentVideo && _currentBgPath.isNotEmpty)
Positioned.fill(
            child: _currentBgPath.startsWith('assets/')
                ? Image.asset(_currentBgPath, fit: BoxFit.cover)
                : (kIsWeb 
                    ? Image.network(_currentBgPath, fit: BoxFit.cover) 
                    : Image.file(File(_currentBgPath), fit: BoxFit.cover)),),

        // 🌸 [핵심 추가] 벚꽃 테마일 때만 터치를 통과하는(IgnorePointer) 애니메이션을 화면 꽉 차게 띄웁니다!
        if (isCherryBlossom)
          const Positioned.fill(
            child: IgnorePointer(child: CherryBlossomOverlay()),
          ),

        widget.child,
      ],
    );
  }
}

// shared_design.dart 파일 하단에 추가
enum PomodoroState { work, shortBreak, longBreak }

ValueNotifier<PomodoroState> globalPomodoroState = ValueNotifier<PomodoroState>(
  PomodoroState.work,
);
ValueNotifier<int> globalCompletedCycles = ValueNotifier<int>(0); // 완료된 뽀모도로 횟수

// shared_design.dart 파일 하단에 추가

/// 뽀모도로 상태를 처음부터 다시 시작하도록 초기화하는 함수
void resetPomodoroStatus() {
  globalPomodoroState.value = PomodoroState.work; // 다시 '집중 모드'로
  globalCompletedCycles.value = 0; // 완료 횟수 0으로

  // 현재 설정된 '집중 시간'을 파싱해서 타이머 시간도 리셋 (옵션)
  // 예: "25분" -> 25 * 60 초로 세팅하는 로직을 호출하거나 변수 직접 수정
}
// shared_design.dart 파일 내 변수 선언 아래쪽에 추가

void initPomodoroResetListener() {
  globalPomodoroMode.addListener(() {
    if (globalPomodoroMode.value == false) {
      // 뽀모도로가 꺼지면 묻지도 따지지도 않고 초기화!
      globalPomodoroState.value = PomodoroState.work;
      globalCompletedCycles.value = 0;
      debugPrint("🍅 뽀모도로 상태가 초기화되었습니다.");
    }
  });
}

// 🔥 사진을 타이머 부채꼴 모양으로 잘라주는 전용 클리퍼 (파일 맨 아래에 추가)
class ClockImageClipper extends CustomClipper<Path> {
  final double drawnSeconds;
  final double maxScaleSeconds;
  final bool isTimer;

  ClockImageClipper(this.drawnSeconds, this.maxScaleSeconds, this.isTimer);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final path = Path();
    
    if (drawnSeconds <= 0) return path; // 남은 시간이 없으면 모두 투명하게 만듦
    if (drawnSeconds >= maxScaleSeconds) {
      path.addOval(Rect.fromCircle(center: center, radius: radius));
      return path; // 시간이 꽉 찼으면 둥근 사진 전체를 보여줌
    }

    // 타이머와 스톱워치 모드에 따라 부채꼴 각도 계산
    final sweepAngle = (drawnSeconds / maxScaleSeconds) * 2 * pi;
    double startAngle = isTimer
        ? -pi / 2 + ((maxScaleSeconds - drawnSeconds) / maxScaleSeconds) * 2 * pi
        : -pi / 2;

    // 부채꼴 모양 경로 생성
    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(ClockImageClipper oldClipper) {
    return oldClipper.drawnSeconds != drawnSeconds ||
           oldClipper.maxScaleSeconds != maxScaleSeconds ||
           oldClipper.isTimer != isTimer;
  }
}
// 🔥 깎여나가는 사진 모양에 맞춰 똑같이 잘리는 똑똑한 그림자 화가!
class PieShadowPainter extends CustomPainter {
  final double drawnSeconds;
  final double maxScaleSeconds;
  final bool isTimer;

  PieShadowPainter(this.drawnSeconds, this.maxScaleSeconds, this.isTimer);

  @override
  void paint(Canvas canvas, Size size) {
    if (drawnSeconds <= 0) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final path = Path();

    if (drawnSeconds >= maxScaleSeconds) {
      path.addOval(Rect.fromCircle(center: center, radius: radius));
    } else {
      final sweepAngle = (drawnSeconds / maxScaleSeconds) * 2 * pi;
      double startAngle = isTimer
          ? -pi / 2 + ((maxScaleSeconds - drawnSeconds) / maxScaleSeconds) * 2 * pi
          : -pi / 2;
      path.moveTo(center.dx, center.dy);
      path.arcTo(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false);
      path.close();
    }

    // 기존 그림자 세팅과 완벽히 동일하게 적용 (오른쪽 아래 4,4 이동 / 블러 15)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);

    final shadowPath = path.shift(const Offset(4.0, 4.0));
    canvas.drawPath(shadowPath, shadowPaint);
  }

  @override
  bool shouldRepaint(PieShadowPainter oldDelegate) {
    return oldDelegate.drawnSeconds != drawnSeconds ||
           oldDelegate.maxScaleSeconds != maxScaleSeconds ||
           oldDelegate.isTimer != isTimer;
  }
}
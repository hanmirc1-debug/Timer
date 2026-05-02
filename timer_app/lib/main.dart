import 'package:flutter/material.dart';
import 'pages/stopwatch_page.dart';
import 'pages/timer_page.dart';
import 'pages/shared_design.dart';
import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_settings_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// 🌟 2. 기존 MobileAds 초기화 코드를 if (!kIsWeb) 으로 감싸기!
  if (!kIsWeb) {
    MobileAds.instance.initialize();
  }
  // 🔥 광고 초기화 (여기 추가)
  //await MobileAds.instance.initialize();
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    await FirebaseSettingsService.loadSettingsFromCloud();
  } else {
    await loadSettings();
  }
  initSettingsListener();
  // 🌟 여기에 뽀모도로 초기화 감지기 시작 코드를 한 줄 추가합니다!
  initPomodoroResetListener();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Manager App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Courier'),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isTimerMode = true;
  bool isRunning = false;
  bool isLocked = false;
  bool showLockIcon = false;
  Timer? _lockTimer;
  Timer? _iconHideTimer;
  DateTime? _touchStartTime;

  final GlobalKey stopwatchKey = GlobalKey();
  final GlobalKey timerKey = GlobalKey();
  final GlobalKey clockKey = GlobalKey();
  final GlobalKey menuKey = GlobalKey();

  final int shortTapMs = 500;
  final int lockDelayMs = 1000;
  final int iconVisibleMs = 2000;

  void _startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer(Duration(milliseconds: lockDelayMs), () {
      setState(() {
        isLocked = !isLocked;
        if (isLocked) {
          _showLockIcon();
        } else {
          showLockIcon = true;
          _showLockIcon();
        }
      });
    });
  }

  void _cancelLockTimer() {
    _lockTimer?.cancel();
    if (isLocked) {
      _showLockIcon();
    }
  }

  void _showLockIcon() {
    setState(() => showLockIcon = true);
    _iconHideTimer?.cancel();
    _iconHideTimer = Timer(Duration(milliseconds: iconVisibleMs), () {
      if (mounted) setState(() => showLockIcon = false);
    });
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _iconHideTimer?.cancel();
    super.dispose();
  }

  void _handleShortTap() {
    if (isLocked) return;
    if (globalIsTimerMode.value) {
      (timerKey.currentState as dynamic).toggle();
    } else {
      (stopwatchKey.currentState as dynamic).toggle();
    }
  }

  bool isBackgroundTouched = false;

  @override
  Widget build(BuildContext context) {
    return GlobalVideoBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              IgnorePointer(
                ignoring: isLocked,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: globalIsTimerMode,
                        builder: (context, isTimer, child) {
                          return isTimer
                              ? TimerAppPage(
                                  key: timerKey,
                                  clockKey: clockKey,
                                  onRunningChanged: (running) {
                                    setState(() => isRunning = running);
                                  },
                                )
                              : StopwatchPage(
                                  key: stopwatchKey,
                                  clockKey: clockKey,
                                  onRunningChanged: (running) {
                                    setState(() => isRunning = running);
                                  },
                                );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  // 1. 세팅 메뉴를 건드렸는지 확인
                  if (menuKey.currentContext != null) {
                    final RenderBox menuBox =
                        menuKey.currentContext!.findRenderObject() as RenderBox;
                    final Offset menuPosition = menuBox.localToGlobal(
                      Offset.zero,
                    );
                    final Size menuSize = menuBox.size;
                    final bool isInsideMenu =
                        event.position.dx >= menuPosition.dx &&
                        event.position.dx <= menuPosition.dx + menuSize.width &&
                        event.position.dy >= menuPosition.dy &&
                        event.position.dy <= menuPosition.dy + menuSize.height;
                    if (isInsideMenu) {
                      isBackgroundTouched = false;
                      return;
                    }
                  }

                  bool isHitClock = false;

                  // 🌟 2. 아날로그 시계(동그라미)를 건드렸는지 정밀 검사!
                  if (analogClockHitKey.currentContext != null) {
                    final box =
                        analogClockHitKey.currentContext!.findRenderObject()
                            as RenderBox;
                    final pos = box.localToGlobal(Offset.zero);
                    final center = Offset(
                      pos.dx + box.size.width / 2,
                      pos.dy + box.size.height / 2,
                    );
                    final radius = box.size.width / 2;
                    final distance = sqrt(
                      pow(event.position.dx - center.dx, 2) +
                          pow(event.position.dy - center.dy, 2),
                    );
                    if (distance <= radius) isHitClock = true;
                  }

                  // 🌟 3. 디지털 시계(네모 글자)를 건드렸는지 정밀 검사!
                  if (digitalClockHitKey.currentContext != null) {
                    final box =
                        digitalClockHitKey.currentContext!.findRenderObject()
                            as RenderBox;
                    final pos = box.localToGlobal(Offset.zero);
                    final rect = pos & box.size;
                    if (rect.contains(event.position)) isHitClock = true;
                  }

                  // 시계 부품 중 하나라도 건드렸다면 배경 터치가 아니므로 잠금 취소!
                  if (isHitClock) {
                    isBackgroundTouched = false;
                    return;
                  }

                  // 🌟 완벽하게 텅 빈 배경을 눌렀을 때만 잠금 시작!
                  isBackgroundTouched = true;
                  _touchStartTime = DateTime.now();
                  _startLockTimer();
                },
                onPointerUp: (_) {
                  if (!isBackgroundTouched) return;
                  final duration = DateTime.now().difference(_touchStartTime!);
                  if (!isLocked && duration.inMilliseconds < shortTapMs) {
                    _handleShortTap();
                  }
                  _cancelLockTimer();
                  isBackgroundTouched = false;
                },
              ),
              Positioned(
                top: 15.0,
                left: 20.0,
                child: Visibility(
                  visible: !isRunning,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: ValueListenableBuilder<Color>(
                    valueListenable: globalBgColor,
                    builder: (context, color, _) {
                      return FloatingGlassMenuButton(
                        key: menuKey,
                        backgroundColor: color,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 15.0,
                right: 20.0,
                child: AnimatedOpacity(
                  opacity: showLockIcon ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLocked ? Icons.lock : Icons.lock_open,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

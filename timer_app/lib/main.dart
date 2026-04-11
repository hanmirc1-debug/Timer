import 'package:flutter/material.dart';
import 'pages/stopwatch_page.dart';
import 'pages/timer_page.dart';
import 'pages/shared_design.dart';
import 'dart:async'; // 잠금 기능용
import 'dart:math';

void main() async {
  // Flutter 엔진 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();
  await loadSettings(); // 🔥 추가
  initSettingsListener(); // 🔥 추가
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Manager App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Courier', // 기본 디지털 느낌 폰트
      ),
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
  bool isTimerMode = true; // false = 스탑워치, true = 타이머

  // =========================================================
  // 🌟 [기능 1] 타이머 작동 감지용 (버튼 숨기기)
  // =========================================================
  bool isRunning = false;

  // =========================================================
  // 🌟 [기능 2] 잠금 기능용 상태 변수들
  // =========================================================
  bool isLocked = false;
  bool showLockIcon = false;
  Timer? _lockTimer;
  Timer? _iconHideTimer;

  DateTime? _touchStartTime;

  final GlobalKey stopwatchKey = GlobalKey();
  final GlobalKey timerKey = GlobalKey();
  final GlobalKey clockKey = GlobalKey(); // 🔥 추가
  final GlobalKey menuKey = GlobalKey(); // 🔥 추가

  final int shortTapMs = 500;

  final int lockDelayMs = 1000; // 배경을 꾹 누르는 시간 (1000 = 1초)
  final int iconVisibleMs = 2000; // 잠금 아이콘이 떠 있는 시간

  // =========================================================
  // 🌟 터치 감지 로직
  // =========================================================
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
    return ValueListenableBuilder<Color>(
      valueListenable: globalBgColor,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: globalBgColor.value,
          body: SafeArea(
            child: Stack(
              children: [
                // ==========================================
                // [1층] 기존 화면들 (잠금 기능 + 실행 중 숨김 모두 적용!)
                // ==========================================
                IgnorePointer(
                  ignoring: isLocked, // 💡 잠기면 터치 무시!
                  child: Stack(
                    children: [
                      // 👇👇👇 수정 1. 설정창의 모드 선택과 실시간 연동되도록 수정! 👇👇👇
                      Positioned.fill(
                        child: ValueListenableBuilder<bool>(
                          valueListenable: globalIsTimerMode,
                          builder: (context, isTimer, child) {
                            return isTimer
                                ? TimerAppPage(
                                    key: timerKey,
                                    clockKey: clockKey, // 🔥 추가
                                    onRunningChanged: (running) {
                                      setState(() => isRunning = running);
                                    },
                                  )
                                : StopwatchPage(
                                    key: stopwatchKey,
                                    clockKey: clockKey, // 🔥 추가
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

                // ==========================================
                // [2층] 터치 감지용 투명 유리판 (화면 전체 덮음)
                // ==========================================
                Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) {
                    // 🔥 0. menuKey null 방어
                    if (menuKey.currentContext != null) {
                      final RenderBox menuBox =
                          menuKey.currentContext!.findRenderObject()
                              as RenderBox;

                      final Offset menuPosition = menuBox.localToGlobal(
                        Offset.zero,
                      );
                      final Size menuSize = menuBox.size;

                      final bool isInsideMenu =
                          event.position.dx >= menuPosition.dx &&
                          event.position.dx <=
                              menuPosition.dx + menuSize.width &&
                          event.position.dy >= menuPosition.dy &&
                          event.position.dy <=
                              menuPosition.dy + menuSize.height;

                      // 👉 🔥 메뉴면 아무것도 하지 말고 끝
                      if (isInsideMenu) {
                        isBackgroundTouched = false; // 🔥 중요
                        return;
                      }
                    }

                    final RenderBox box =
                        clockKey.currentContext!.findRenderObject()
                            as RenderBox;

                    final position = box.localToGlobal(Offset.zero);
                    final size = box.size;

                    final center = Offset(
                      position.dx + size.width / 2,
                      position.dy + size.height / 2,
                    );

                    final radius = size.width / 2;

                    final dx = event.position.dx - center.dx;
                    final dy = event.position.dy - center.dy;
                    final distance = sqrt(dx * dx + dy * dy);

                    if (distance <= radius) return;

                    // 👉 시계 영역 "밖"만 허용
                    if (distance > radius) {
                      isBackgroundTouched = true;

                      _touchStartTime = DateTime.now();
                      _startLockTimer();
                    }
                  },
                  onPointerUp: (_) {
                    if (!isBackgroundTouched) return;

                    final duration = DateTime.now().difference(
                      _touchStartTime!,
                    );

                    // 🔥 핵심: lock 안된 경우만 shortTap
                    if (!isLocked && duration.inMilliseconds < shortTapMs) {
                      _handleShortTap();
                    }

                    _cancelLockTimer();
                    isBackgroundTouched = false;
                  },
                ),

                // 메뉴 버튼
                Positioned(
                  top: 15.0,
                  left: 20.0,
                  child: Visibility(
                    visible: !isRunning,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: FloatingGlassMenuButton(
                      backgroundColor: globalBgColor.value,
                    ),
                  ),
                ),
                
                // ==========================================
                // [3층] 자물쇠 아이콘 (맨 위)
                // ==========================================
                Positioned(
                  top: 15.0, // 💡 메뉴 버튼과 완벽하게 동일한 높이로 수정 완료 (70 -> 15)
                  right: 20.0,
                  child: AnimatedOpacity(
                    opacity: showLockIcon ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(10), // 💡 아이콘 여백을 키워서 버튼 크기 확대 (8 -> 10)
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocked ? Icons.lock : Icons.lock_open,
                        color: Colors.white,
                        size: 24, // 💡 아이콘 자체 크기도 확대 (20 -> 24)
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
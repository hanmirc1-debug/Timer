import 'package:flutter/material.dart';
import 'pages/stopwatch_page.dart';
import 'pages/timer_page.dart';
import 'pages/shared_design.dart';
import 'dart:async';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSettings(); 
  initSettingsListener(); 
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
        fontFamily: 'Courier', 
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
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
        if (isLocked) { _showLockIcon(); } else { showLockIcon = true; _showLockIcon(); }
      });
    });
  }

  void _cancelLockTimer() {
    _lockTimer?.cancel();
    if (isLocked) { _showLockIcon(); }
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
    _lockTimer?.cancel(); _iconHideTimer?.cancel(); super.dispose();
  }

  void _handleShortTap() {
    if (isLocked) return;
    if (globalIsTimerMode.value) { (timerKey.currentState as dynamic).toggle(); } else { (stopwatchKey.currentState as dynamic).toggle(); }
  }

  bool isBackgroundTouched = false;

  @override
  Widget build(BuildContext context) {
    // 💡 [핵심 추가됨] 여기서 화면 전체를 비디오 배경 위젯으로 감싸줍니다!
    return GlobalVideoBackground(
      child: Scaffold(
        // 영상이 보일 수 있게 배경색을 투명하게 설정!
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
                              ? TimerAppPage(key: timerKey, clockKey: clockKey, onRunningChanged: (running) { setState(() => isRunning = running); })
                              : StopwatchPage(key: stopwatchKey, clockKey: clockKey, onRunningChanged: (running) { setState(() => isRunning = running); });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  if (menuKey.currentContext != null) {
                    final RenderBox menuBox = menuKey.currentContext!.findRenderObject() as RenderBox;
                    final Offset menuPosition = menuBox.localToGlobal(Offset.zero);
                    final Size menuSize = menuBox.size;
                    final bool isInsideMenu = event.position.dx >= menuPosition.dx && event.position.dx <= menuPosition.dx + menuSize.width && event.position.dy >= menuPosition.dy && event.position.dy <= menuPosition.dy + menuSize.height;
                    if (isInsideMenu) { isBackgroundTouched = false; return; }
                  }
                  final RenderBox box = clockKey.currentContext!.findRenderObject() as RenderBox;
                  final position = box.localToGlobal(Offset.zero);
                  final size = box.size;
                  final center = Offset(position.dx + size.width / 2, position.dy + size.height / 2);
                  final radius = size.width / 2;
                  final dx = event.position.dx - center.dx;
                  final dy = event.position.dy - center.dy;
                  final distance = sqrt(dx * dx + dy * dy);

                  if (distance <= radius) return;
                  if (distance > radius) {
                    isBackgroundTouched = true; _touchStartTime = DateTime.now(); _startLockTimer();
                  }
                },
                onPointerUp: (_) {
                  if (!isBackgroundTouched) return;
                  final duration = DateTime.now().difference(_touchStartTime!);
                  if (!isLocked && duration.inMilliseconds < shortTapMs) { _handleShortTap(); }
                  _cancelLockTimer(); isBackgroundTouched = false;
                },
              ),
              Positioned(
                top: 15.0, left: 20.0,
                child: Visibility(
                  visible: !isRunning, maintainSize: true, maintainAnimation: true, maintainState: true,
                  child: ValueListenableBuilder<Color>(
                    valueListenable: globalBgColor,
                    builder: (context, color, _) {
                      return FloatingGlassMenuButton(backgroundColor: color);
                    }
                  ),
                ),
              ),
              Positioned(
                top: 15.0, right: 20.0,
                child: AnimatedOpacity(
                  opacity: showLockIcon ? 1.0 : 0.0, duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                    child: Icon(isLocked ? Icons.lock : Icons.lock_open, color: Colors.white, size: 24),
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
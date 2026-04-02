import 'package:flutter/material.dart';
import 'pages/stopwatch_page.dart';
import 'pages/timer_page.dart';
import 'pages/shared_design.dart'; 
import 'dart:async'; // 잠금 기능용

void main() {
  // Flutter 엔진 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();
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
  Color myBgColor = const Color.fromARGB(255, 77, 77, 116); // 💡 배경색 원하시면 여기서 변경!

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

  final int lockDelayMs = 1000;   // 배경을 꾹 누르는 시간 (1000 = 1초)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myBgColor,
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
                  // 1. 메인 화면 (isRunning 상태 업데이트 받기)
                  Positioned.fill(
                    child: isTimerMode
                        ? TimerAppPage(
                            onRunningChanged: (running) {
                              setState(() => isRunning = running);
                            },
                          )
                        : StopwatchPage(
                            onRunningChanged: (running) {
                              setState(() => isRunning = running);
                            },
                          ),
                  ),

                  // 2. 상단 바 영역 (isRunning이 true면 투명하게 숨김!)
                  Positioned(
                    top: 15.0,
                    left: 20.0,
                    right: 20.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 좌측 메뉴 버튼
                        Visibility(
                          visible: !isRunning,
                          maintainSize: true,       
                          maintainAnimation: true,  
                          maintainState: true,      
                          child: FloatingGlassMenuButton(backgroundColor: myBgColor),
                        ),
                        // 우측 스위치 버튼
                        Visibility(
                          visible: !isRunning,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: FloatingGlassSwitchButton(
                            value: isTimerMode,
                            onChanged: (value) => setState(() => isTimerMode = value),
                          ),
                        ),
                      ],
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
              onPointerDown: (_) => _startLockTimer(), 
              onPointerUp: (_) => _cancelLockTimer(),  
              onPointerCancel: (_) => _cancelLockTimer(),
              child: const SizedBox.expand(),
            ),

            // ==========================================
            // [3층] 자물쇠 아이콘 (맨 위)
            // ==========================================
            Positioned(
              top: 70.0, 
              right: 20.0, 
              child: AnimatedOpacity(
                opacity: showLockIcon ? 1.0 : 0.0, 
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLocked ? Icons.lock : Icons.lock_open, 
                    color: Colors.white, 
                    size: 20
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart'; // 가로 모드 고정을 위해 필요
import 'pages/stopwatch_page.dart';
import 'pages/timer_page.dart';
import 'pages/shared_design.dart'; // 수정된 디자인 코드를 불러옴
import 'dart:async'; // 잠금기능

void main() {
  // Flutter 엔진 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();

  // 가로 모드로 방향 고정
  // SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.landscapeRight,
  //   DeviceOrientation.landscapeLeft,
  // ]).then((_) {
  runApp(const MyApp());
  // });
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
  Color myBgColor = const Color.fromARGB(255, 77, 77, 116);

  // =========================================================
  // 🌟 1. 잠금 기능용 상태 변수들 추가
  // =========================================================
  bool isLocked = false;
  bool showLockIcon = false;
  Timer? _lockTimer;
  Timer? _iconHideTimer;

  // 원하는 시간으로 수정 가능! (1000 = 1초)
  final int lockDelayMs = 1000;   // 배경을 꾹 누르는 시간
  final int iconVisibleMs = 2000; // 잠금 아이콘이 떠 있는 시간

  // =========================================================
  // 🌟 2. 터치 감지 로직 추가
  // =========================================================
  void _startLockTimer() {
    _lockTimer?.cancel();
    // 손을 대고 1초(lockDelayMs)가 지나면 실행됨
    _lockTimer = Timer(Duration(milliseconds: lockDelayMs), () {
      setState(() {
        isLocked = !isLocked; // 잠금 <-> 해제 상태 반전!
        if (isLocked) {
          _showLockIcon(); // 잠기면 바로 자물쇠 보여주기
        } else {
          // 풀릴 때는 열린 자물쇠를 잠깐 보여주고 싶다면 showLockIcon = true 후 타이머 돌려도 됩니다!
          // 지금은 깔끔하게 바로 숨기기
          showLockIcon = true; 
          _showLockIcon(); 
        }
      });
    });
  }

  void _cancelLockTimer() {
    _lockTimer?.cancel(); // 1초가 되기 전에 손을 떼면 잠금 취소
    
    // 이미 잠긴 상태에서 짧게 터치만 했을 때 아이콘 띄우기
    if (isLocked) {
      _showLockIcon();
    }
  }

  void _showLockIcon() {
    setState(() => showLockIcon = true);
    _iconHideTimer?.cancel();
    _iconHideTimer = Timer(Duration(milliseconds: iconVisibleMs), () {
      if (mounted) setState(() => showLockIcon = false); // 2초 뒤 스르륵 사라짐
    });
  }

  @override
  void dispose() {
    // 페이지가 꺼질 때 메모리 누수 방지용
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
            // [1층] 기존 화면들 (가장 밑으로 내립니다)
            // ==========================================
            IgnorePointer(
              ignoring: isLocked, // 잠기면 이 안의 터치가 전부 무시됨
              child: Stack(
                children: [
                  Positioned.fill(
                    child: isTimerMode ? const TimerAppPage() : const StopwatchPage(),
                  ),
                  Positioned(
                    top: 15.0,
                    left: 20.0,
                    right: 20.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FloatingGlassMenuButton(backgroundColor: myBgColor),
                        FloatingGlassSwitchButton(
                          value: isTimerMode,
                          onChanged: (value) => setState(() => isTimerMode = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // [2층] 터치 감지용 투명 유리판 (화면 전체를 덮음!)
            // ==========================================
            Listener(
              // 💡 핵심: translucent를 쓰면 터치를 감지하면서도 밑에 있는 버튼이 눌리게 통과시켜 줍니다!
              behavior: HitTestBehavior.translucent, 
              onPointerDown: (_) => _startLockTimer(), // 마우스/손가락 누를 때
              onPointerUp: (_) => _cancelLockTimer(),  // 뗄 때
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
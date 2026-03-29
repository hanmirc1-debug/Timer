import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 가로 모드 고정을 위해 필요
import 'pages/stopwatch_page.dart';
import 'pages/timer_page.dart';
import 'pages/shared_design.dart'; // 수정된 디자인 코드를 불러옴

void main() {
  // Flutter 엔진 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();
  
  // 가로 모드로 방향 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]).then((_) {
    runApp(const MyApp());
  });
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
  bool isTimerMode = false; // false = 스탑워치, true = 타이머

  @override
  Widget build(BuildContext context) {
    // 7. 배경화면 완전 흰색
    return Scaffold(
      backgroundColor: Colors.white, 
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바 영역 (수정됨: 메뉴, 스위치 플로팅)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1, 3. 왼쪽 위 플로팅 메뉴 버튼 (점 세개로 변경)
                  FloatingGlassMenuButton(),
                  
                  // 2. 오른쪽 위 플로팅 모드 변경 스위치
                  FloatingGlassSwitchButton(
                    value: isTimerMode,
                    onChanged: (value) {
                      setState(() {
                        isTimerMode = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // 메인 화면 영역 (토글 상태에 따라 위젯 변경)
            Expanded(
              child: isTimerMode ? const TimerAppPage() : const StopwatchPage(),
            ),
          ],
        ),
      ),
    );
  }
}
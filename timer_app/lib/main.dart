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
  bool isTimerMode = true; // false = 스탑워치, true = 타이머
  Color myBgColor = const Color.fromARGB(255, 255, 255, 255); // 👈 진짜 배경색 변수를 하나 만듭니다! 나중에 여기에 현재 배경 색 변수 넣어야댐!

  @override
  Widget build(BuildContext context) {
    // 7. 배경화면
    return Scaffold(
      //backgroundColor: const Color.fromARGB(255, 0, 0, 0), 
      backgroundColor: myBgColor, 
      body: SafeArea(
        child: Stack(
                  children: [
                    // 1. 메인 화면 (이제 남은 공간이 아니라 화면 전체를 도화지로 씁니다)
                    Positioned.fill(
                      child: isTimerMode ? const TimerAppPage() : const StopwatchPage(),
                    ),
                    
                    // 2. 상단 바 영역 (버튼들이 공간을 차지하지 않고 화면 맨 위에 떠 있음)
                    Positioned(
                      top: 15.0,
                      left: 20.0,
                      right: 20.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FloatingGlassMenuButton(
                            backgroundColor: myBgColor, // 지금 배경색을 버튼한테 알려줌!
                          ),
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
          ],
        ),
      ),
    );
  }
}
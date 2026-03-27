import 'package:flutter/material.dart';
import 'pages/timer_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Timer App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TimerPage(), // ⭐ 여기 중요 wjdgus221
    );
  }
}
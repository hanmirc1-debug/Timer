import 'package:flutter/material.dart';

class BasePopup extends StatelessWidget {
  final String title;

  const BasePopup({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    
    return Center(
      child: Material(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: screen.width * (2 / 3),
          height: screen.height * (3 / 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text("더미입니다.", style: TextStyle(fontSize: 20)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("닫기"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
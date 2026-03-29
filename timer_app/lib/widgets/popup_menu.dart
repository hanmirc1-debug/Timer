import 'package:flutter/material.dart';

class CustomPopupMenu extends StatelessWidget {
  final Offset position;
  final Size buttonSize;

  const CustomPopupMenu({
    super.key,
    required this.position,
    required this.buttonSize,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(color: Colors.transparent),
        ),
        Positioned(
          top: position.dy + buttonSize.height,
          left: position.dx,
          child: Material(
            borderRadius: BorderRadius.circular(20),
            elevation: 10,
            child: Container(
              width: screen.width * 0.25,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _menuItem(context, "타이머 추가"),
                  _menuItem(context, "설정"),
                  _menuItem(context, "삭제"),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuItem(BuildContext context, String text) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Text(text),
      ),
    );
  }
}
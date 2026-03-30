import 'package:flutter/material.dart';
import 'widgets.dart'; // BasePopup을 불러옵니다.

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
        Center(
          child: Material(
            borderRadius: BorderRadius.circular(20),
            elevation: 10,
            child: Container(
              width: screen.width * (1 / 3), // 가로 1/3
              height: screen.height * (3 / 5), // 세로 3/5
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _menuItem(context, "옵션"),
                    _menuItem(context, "즐겨찾기"),
                    _menuItem(context, "계정연동"),
                    _menuItem(context, "추가1"),
                    _menuItem(context, "시계 설정"),
                  ],
                ),
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
        if (text == "옵션") {
          showDialog(
            context: context,
            barrierColor: Colors.black54,
            builder: (_) => OptionPopup(),
          );
        } else if (text == "즐겨찾기") {
          showDialog(
            context: context,
            barrierColor: Colors.black54,
            builder: (_) => FavoritePopup(),
          );
        } else if (text == "계정연동") {
          showDialog(
            context: context,
            barrierColor: Colors.black54,
            builder: (_) => AccountPopup(),
          );
        } else if (text == "추가1") {
          showDialog(
            context: context,
            barrierColor: Colors.black54,
            builder: (_) => ExtraPopup(),
          );
        } else if (text == "시계 설정") {
          showDialog(
            context: context,
            barrierColor: Colors.black54,
            builder: (_) => ClockSettingPopup(),
          );
        }
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

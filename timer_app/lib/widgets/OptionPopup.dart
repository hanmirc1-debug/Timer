import 'package:flutter/material.dart';
import 'widgets.dart'; // BasePopup을 불러옵니다.

class OptionPopup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BasePopup(title: "옵션");
  }
}

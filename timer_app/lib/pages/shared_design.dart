import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart'; // 애플 스타일 스위치를 쓰기 위해 필수!

import 'package:timer_app/widgets/popup_menu.dart';
// =========================================================
// 🌟 0. 앱 전체 공유 설정값 (여기에 두어야 모든 페이지에서 꺼내 씁니다)
// =========================================================
// 시계 스타일
final ValueNotifier<String> globalDisplayMode = ValueNotifier<String>("both"); 
// 숫자 or 점
final ValueNotifier<String> globalIndicatorMode = ValueNotifier<String>("number");
//디지털 폰트 스타일
final ValueNotifier<String> globalDigitalStyle = ValueNotifier<String>("default"); // "default", "segment", "flip"

// // =========================================================
// // 🌟 1. 공통 깔끔한 껍데기 
// // =========================================================
// class FloatingGlassContainer extends StatelessWidget {
//   final Widget child;
//   final EdgeInsetsGeometry padding;

//   const FloatingGlassContainer({
//     super.key, 
//     required this.child,
//     this.padding = const EdgeInsets.all(5), 
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       // 1. 토스 스타일의 핵심: 투박한 elevation 대신 아주 부드럽고 넓게 퍼지는 그림자 직접 제어
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(25.0),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06), // 그림자를 엄청 연하고 고급스럽게!
//             blurRadius: 20, // 뭉치지 않고 넓게 퍼지게
//             spreadRadius: 1,
//             offset: const Offset(0, 4), // 빛이 위에서 아래로 비추는 느낌
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.white, // 지저분한 반투명 회색 싹 빼고 완벽한 순백색!
//         borderRadius: BorderRadius.circular(15.0),
//         clipBehavior: Clip.antiAlias, // 터치 효과(물결)가 동그란 테두리 밖으로 안 삐져나가게 방지
//         child: Padding(
//           padding: padding,
//           child: child, 
//         ),
//       ),
//     );
//   }
// }
class FloatingGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FloatingGlassContainer({
    super.key, 
    required this.child,
    this.padding = const EdgeInsets.all(5), 
  });

  @override
  Widget build(BuildContext context) {
    // 거추장스러운 Container와 boxShadow(그림자)를 통째로 날려버렸습니다.
    return Material(
      color: Colors.transparent, // 배경을 완전 투명하게 만들어서 종이처럼 찰싹 붙임
      elevation: 0, // 입체감(그림자) 제로!!
      borderRadius: BorderRadius.circular(20.0),
      clipBehavior: Clip.antiAlias, // 터치할 때만 동그랗게 물결 효과 나오게 유지
      child: Padding(
        padding: padding,
        child: child, 
      ),
    );
  }
}
// =========================================================
// 2. 텍스트 버튼 (시작, 멈춤, 리셋) - 공통 껍데기 적용
// =========================================================
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const GlassButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingGlassContainer(
      padding: EdgeInsets.zero, // 터치 효과(Ripple)를 위해 패딩은 안쪽으로 넘김
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// 3. 상단 메뉴 버튼 (점 세개) - 공통 껍데기
// =========================================================
class FloatingGlassMenuButton extends StatelessWidget {
  // 💡 버튼 뒤에 깔려있는 진짜 배경색을 전달받을 변수입니다.
  final Color backgroundColor;

  FloatingGlassMenuButton({super.key, required this.backgroundColor});
  
  final GlobalKey _buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    
    // 🎨 [핵심!] 전달받은 배경색의 밝기(Luminance)를 수치로 계산합니다.
    // 보통 0.5를 기준으로 그보다 크면 밝은 배경, 작으면 어두운 배경으로 판단합니다.
    Color iconColor = backgroundColor.computeLuminance() > 0.5 
        ? Colors.black87 // 배경이 밝음 -> 아이콘은 검은색
        : Colors.white;  // 배경이 어두움 -> 아이콘은 흰색

    return FloatingGlassContainer(
      child: IconButton(
        key: _buttonKey,
        // 👇 계산된 똑똑한 색상(iconColor)을 적용!
        icon: Icon(Icons.more_horiz, size: 24, color: iconColor),
        onPressed: () {
          final RenderBox box = _buttonKey.currentContext!.findRenderObject() as RenderBox;
          final position = box.localToGlobal(Offset.zero);
          final size = box.size;

          showDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (_) => CustomPopupMenu(
              position: position,
              buttonSize: size,
            ),
          );
        },
      ),
    );
  }
}
// =========================================================
// 4. 상단 스위치 버튼 - 공통 껍데기 적용
// =========================================================
// class FloatingGlassSwitchButton extends StatelessWidget {
//   final bool value;
//   final ValueChanged<bool> onChanged;

//   const FloatingGlassSwitchButton({super.key, required this.value, required this.onChanged});

//   @override
//   Widget build(BuildContext context) {
//     return FloatingGlassContainer(
//       child: Switch(
//         value: value,
//         activeColor: Colors.black, 
//         onChanged: onChanged,
//       ),
//     );
//   }
// }
// =========================================================
class FloatingGlassSwitchButton extends StatefulWidget {
  final bool value; // 동그라미 위치 (false=왼쪽 TM, true=오른쪽 SW)
  final ValueChanged<bool> onChanged;

  const FloatingGlassSwitchButton({super.key, required this.value, required this.onChanged});

  @override
  State<FloatingGlassSwitchButton> createState() => _FloatingGlassSwitchButtonState();
}

class _FloatingGlassSwitchButtonState extends State<FloatingGlassSwitchButton> {
  @override
  Widget build(BuildContext context) {
    // 1. 값에 따라 표시될 텍스트 결정
    // 동그라미가 오른쪽에있을때는 글자가 TM, 왼쪽에 있을때는ㄴ SW
    // widget.value가 true면 오른쪽 -> 스, false면 왼쪽 -> ㄵ
    String displayText = widget.value ? "TM" : "SW";

    return GestureDetector(
      // 2. 전체 스위치를 터치하면 값을 토글합니다.
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: Container(
        child: Container(
          // track 모양: 넓고 동그란 track
          width: 90, // 텍스트를 담기 위해 기존 스위치보다 넓게
          height: 38, // 트랙 높이
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 231, 231, 231), // 트랙 배경색
            borderRadius: BorderRadius.circular(15), // 트랙 끝을 완벽하게 동그랗게
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // [수정] 텍스트 ("SW" 또는 "TM") 위치 변경: 동그라미 반대쪽으로
              Align(
                // widget.value가 true (오른쪽 핸들) -> 텍스트는 Alignment.centerLeft
                // widget.value가 false (왼쪽 핸들) -> 텍스트는 Alignment.centerRight
                alignment: widget.value ? Alignment.centerLeft : Alignment.centerRight,
                child: Padding(
                  // 텍스트 위치 세부 조정: 반대쪽 끝에 붙게 padding 추가
                  padding: widget.value 
                      ? const EdgeInsets.only(left: 12) // SW일 때 왼쪽 여백
                      : const EdgeInsets.only(right: 12), // TM일 때 오른쪽 여백
                  child: Text(
                    displayText,
                    style: const TextStyle(
                      color: Color.fromARGB(240, 121, 121, 121),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // 애니메이션 동그라미 핸들 (동일하게 유지)
              AnimatedAlign(
                duration: const Duration(milliseconds: 200), // 애니메이션 속도
                // true면 오른쪽(centerRight), false면 왼쪽(centerLeft)으로 핸들 이동
                alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4), // 트랙 끝과의 여백
                  child: Container(
                    width: 30, // 동그라미 크기
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(240, 121, 121, 121), // 핸들 색상
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}// 4. 시계 그리기 (점/숫자 모드 분기 처리 완료)
class SharedClockPainter extends CustomPainter {
  final double drawnSeconds;
  final double maxScaleSeconds;
  final bool isTimer; 
  final String indicatorMode;

  // 기본값을 설정해둡니다.
  SharedClockPainter(this.drawnSeconds, this.maxScaleSeconds, {this.isTimer = true, this.indicatorMode = "number"});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 빨간색 부채꼴 크기
    final sweepAngle = (drawnSeconds / maxScaleSeconds) * 2 * pi;
    
    double startAngle;
    if (isTimer) {
      startAngle = -pi / 2 + ((maxScaleSeconds - drawnSeconds) / maxScaleSeconds) * 2 * pi;
    } else {
      startAngle = -pi / 2;
    }

    final paintArc = Paint()
      ..color = const Color.fromARGB(255, 240, 14, 14).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    if (drawnSeconds > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paintArc,
      );
    }
    
    // =============================================================
    // [미니멀 분 선 블록]
    final tickPaint = Paint()
      ..color = const Color.fromARGB(255, 0, 0, 0).withOpacity(0.5) 
      ..strokeWidth = 1.0; 

    final fiveTickPaint = Paint()
      ..color = const Color.fromARGB(255, 0, 0, 0).withOpacity(0.7) 
      ..strokeWidth = 2.0; 

    for (int t = 0; t < 60; t++) {
      final angle = (t / 60) * 2 * pi - pi / 2;
      bool isFiveMinute = t % 5 == 0;
      Paint currentPaint = isFiveMinute ? fiveTickPaint : tickPaint;
      double innerRadiusRatio = isFiveMinute ? 0.92 : 0.96;

      canvas.drawLine(
        center + Offset(cos(angle) * (radius * innerRadiusRatio), sin(angle) * (radius * innerRadiusRatio)),
        center + Offset(cos(angle) * radius, sin(angle) * radius),
        currentPaint, 
      );
    }
    // =============================================================
    
    final double relativeFontSize = radius * 0.1;
    // 숫자 위치 0.8이면 원안쪽으로 들어옴
    final double relativePadding = radius * 1.08;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // 👇👇👇 여기가 핵심 수정 부분입니다! (점/숫자 분기 처리) 👇👇👇
for (int i = 0; i < maxScaleSeconds; i += 5) {
      
      // 만약 설정이 "none"(표시 안 함)이면, 이 밑에 코드는 싹 무시하고 다음 칸으로 넘어감!
      if (indicatorMode == "none") continue; 

      double angle;
      if (isTimer) {
        angle = -pi / 2 - (i / maxScaleSeconds) * 2 * pi;
      } else {
        angle = -pi / 2 + (i / maxScaleSeconds) * 2 * pi;
      }
      final x = center.dx + relativePadding * cos(angle);
      final y = center.dy + relativePadding * sin(angle);

      if (indicatorMode == "dot") {
        // [점 모드]
        final dotPaint = Paint()..color = const Color.fromARGB(255, 121, 121, 121)..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), radius * 0.03, dotPaint); 
      } else if (indicatorMode == "number") {
        // [숫자 모드] 
        textPainter.text = TextSpan(
          text: '$i',
          style: TextStyle(fontSize: relativeFontSize, color: Colors.black, fontWeight: FontWeight.bold),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
// 5. 디지털 폰트 함수
String formatDigitalTimeLong(double seconds) {
  int s = seconds.toInt();
  int h = s ~/ 3600;
  int m = (s % 3600) ~/ 60;
  s = s % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

// =========================================================
// 6. 다기능 디지털 시계 위젯 (기본 / 세그먼트 / 플립)
// =========================================================
// =========================================================
// 🌟 다기능 디지털 시계 위젯 (기본 / 세그먼트 / 플립 애니메이션 추가!)
// =========================================================
class CustomDigitalClock extends StatelessWidget {
  final double seconds;
  final String styleMode; // "default", "segment", "flip"
  final double fontSize;
  final Color defaultColor;

  const CustomDigitalClock({
    super.key,
    required this.seconds,
    required this.styleMode,
    required this.fontSize,
    this.defaultColor = Colors.redAccent,
  });

  @override
  Widget build(BuildContext context) {
    String timeString = formatDigitalTimeLong(seconds);

    if (styleMode == "flip") {
      // 🕰️ [찐 플립 시계 스타일] - 새로 만든 클래스를 갖다 쓰기만 하면 끝!
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: timeString.split('').map((char) {
          if (char == ':') {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(':', style: TextStyle(fontSize: fontSize * 0.8, fontWeight: FontWeight.bold, color: Colors.black)),
            );
          }
          // 💡 복잡했던 코드 대신 한 줄로 해결!
          return ClassicFlipDigit(digit: char, fontSize: fontSize);
        }).toList(),
      );

    } else if (styleMode == "segment") {
      // 📟 [전자시계 세그먼트 스타일]
      return Text(
        timeString,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900, 
          fontStyle: FontStyle.italic, 
          letterSpacing: 4.0,
          color: defaultColor,
          fontFamily: 'Courier', 
          shadows: [
            Shadow(color: defaultColor.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 0)),
          ],
        ),
      );

    } else {
      // ⏱️ [기본 둥근 스타일]
      return Text(
        timeString,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
          color: defaultColor, 
        ),
      );
    }
  }
}

// =========================================================
// 아날로그 플립 카드 (위에서 아래로 반 접히는 달력 효과)
// =========================================================
class ClassicFlipDigit extends StatefulWidget {
  final String digit;
  final double fontSize;
  const ClassicFlipDigit({super.key, required this.digit, required this.fontSize});

  @override
  State<ClassicFlipDigit> createState() => _ClassicFlipDigitState();
}

class _ClassicFlipDigitState extends State<ClassicFlipDigit> with SingleTickerProviderStateMixin {
  late String _currentDigit;
  late String _nextDigit;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _currentDigit = widget.digit;
    _nextDigit = widget.digit;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _currentDigit = _nextDigit);
        }
      });
  }

  @override
  void didUpdateWidget(ClassicFlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.digit != oldWidget.digit) {
      _nextDigit = widget.digit;
      _controller.forward(from: 0.0);
    }
  }

  // 카드를 위/아래 정확히 반으로 자르는 함수
  Widget _buildHalf(String digit, bool isTop) {
    return ClipRect(
      child: Align(
        alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
        heightFactor: 0.5,
        child: Container(
          width: widget.fontSize * 0.85, // 카드 너비 고정 (숫자 바뀔 때 안 흔들리게)
          alignment: Alignment.center,
          // 위아래 여백 늘리기
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // 진한 흑회색
            borderRadius: BorderRadius.vertical(
              top: isTop ? const Radius.circular(8.0) : Radius.zero,
              bottom: isTop ? Radius.zero : const Radius.circular(8.0),
            ),
          ),
          child: Text(
            digit,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final isFirstHalf = _animation.value < 0.5;
        Widget topHalf;
        Widget bottomHalf;

        if (isFirstHalf) {
          // [1단계] 윗장이 90도까지 앞으로 꺾이며 접히는 중
          final flipValue = _animation.value * 2; 
          topHalf = Stack(
            children: [
              _buildHalf(_nextDigit, true), // 뒤에 깔려있는 다음 숫자 윗장
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.003)
                  ..rotateX(-flipValue * (pi / 2)), // 💡 위에서 앞으로 넘어짐
                alignment: Alignment.bottomCenter, // 가운데 선이 축
                child: _buildHalf(_currentDigit, true), // 현재 숫자 윗장
              ),
            ],
          );
          bottomHalf = _buildHalf(_currentDigit, false); // 아래는 아직 그대로
        } else {
          // [2단계] 90도를 넘어 바닥에 찰싹 달라붙는 중
          final flipValue = (_animation.value - 0.5) * 2; 
          topHalf = _buildHalf(_nextDigit, true); // 윗장은 이미 다음 숫자로 변함
          bottomHalf = Stack(
            children: [
              _buildHalf(_currentDigit, false), // 뒤에 깔려있는 원래 숫자 아랫장
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.003)
                  ..rotateX((1.0 - flipValue) * (pi / 2)), // 💡 허공에서 바닥으로 떨어짐
                alignment: Alignment.topCenter, // 가운데 선이 축
                child: _buildHalf(_nextDigit, false), // 다음 숫자 아랫장
              ),
            ],
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              topHalf,
              Container(height: 2.0, width: widget.fontSize * 0.7, color: Colors.black87), // 절취선
              bottomHalf,
            ],
          ),
        );
      },
    );
  }
}
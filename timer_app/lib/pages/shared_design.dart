import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
//import 'package:flutter/cupertino.dart'; // 애플 스타일 스위치를 쓰기 위해 필수!
//import 'package:timer_app/widgets/popup_menu.dart';
import 'settings_page.dart';

// =========================================================
// 🌟 0. 앱 전체 공유 설정값 (여기에 두어야 모든 페이지에서 꺼내 씁니다)
// =========================================================
// 시계 스타일
final ValueNotifier<String> globalDisplayMode = ValueNotifier<String>("both");
final ValueNotifier<Color> globalBgColor = ValueNotifier(
  const Color(0xFF000000),
); // 검정

final ValueNotifier<Color> globalClockColor = ValueNotifier(
  const Color(0xFFFF0000),
); // 빨강

final ValueNotifier<Color> globalDigitalColor = ValueNotifier(
  const Color(0xFF00FF00),
); // 초록

final ValueNotifier<Color> globalIndicatorColor = ValueNotifier(
  const Color(0xFFFFFFFF),
); // 흰색
// 숫자 or 점
final ValueNotifier<String> globalIndicatorMode = ValueNotifier<String>(
  "number",
);
//디지털 폰트 스타일
final ValueNotifier<String> globalDigitalStyle = ValueNotifier<String>(
  "default",
); // "default", "segment", "flip"

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
      child: Padding(padding: padding, child: child),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
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
  final Color backgroundColor;

  FloatingGlassMenuButton({super.key, required this.backgroundColor});

  final GlobalKey _buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    Color iconColor = backgroundColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    // 👇👇👇 1. Align을 써서 부모가 누구든 무조건 '왼쪽 위(topLeft)'로 강제 이동! 👇👇👇
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        // 💡 2. 이제 여기서 진짜 원하는 만큼만 벽에서 떨어뜨립니다. (너무 0이면 윗부분 시계/배터리에 가려지니 약간은 띄우는 게 좋습니다)
        padding: EdgeInsets.only(
          top: screenHeight * 0.00, // 위에서 6%
          left: screenWidth * 0.00, // 왼쪽에서 5%
        ),
        child: FloatingGlassContainer(
          padding: EdgeInsets.zero, // 💡 불필요한 이중 여백 제거
          child: IconButton(
            key: _buttonKey,
            padding: EdgeInsets.all(screenWidth * 0.02), // 순수 터치 영역만 남김
            // 👇👇👇 3. 플러터 기본 버튼의 '보이지 않는 투명 보호막(48px)' 제거! 👇👇👇
            constraints: const BoxConstraints(),

            icon: Icon(
              Icons.more_horiz,
              size: screenWidth * 0.04,
              color: iconColor,
            ),
            onPressed: () {
              // 💡 화려한 애니메이션 제거! 가장 기본적이고 깔끔한 페이지 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            // onPressed: () {
            //               // 💡 렉/검은화면 완벽 해결!
            //               // 투박한 안드로이드 기본 전환 대신, 아이폰(Cupertino) 스타일의 부드러운 슬라이드 애니메이션 적용
            //               Navigator.push(
            //                 context,
            //                 PageRouteBuilder(
            //                   transitionDuration: const Duration(milliseconds: 300), // 애니메이션 속도
            //                   pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(),
            //                   transitionsBuilder: (context, animation, secondaryAnimation, child) {
            //                     const begin = Offset(1.0, 0.0); // 오른쪽에서 왼쪽으로 등장
            //                     const end = Offset.zero;
            //                     const curve = Curves.easeInOutQuart; // 아주 부드러운 가감속 곡선

            //                     var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            //                     var offsetAnimation = animation.drive(tween);

            //                     return SlideTransition(position: offsetAnimation, child: child);
            //                   },
            //                 ),
            //               );
            //             },
          ),
        ),
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
// class FloatingGlassSwitchButton extends StatefulWidget {
//   final bool value; // 동그라미 위치 (false=왼쪽 TM, true=오른쪽 SW)
//   final ValueChanged<bool> onChanged;

//   const FloatingGlassSwitchButton({
//     super.key,
//     required this.value,
//     required this.onChanged,
//   });

//   @override
//   State<FloatingGlassSwitchButton> createState() =>
//       _FloatingGlassSwitchButtonState();
// }
// =========================================================
// 4. 상단 스위치 버튼 - 공통 껍데기 적용
// =========================================================
class FloatingGlassSwitchButton extends StatefulWidget {
  final bool value; // 동그라미 위치 (false=왼쪽 TM, true=오른쪽 SW)
  final ValueChanged<bool> onChanged;

  const FloatingGlassSwitchButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<FloatingGlassSwitchButton> createState() =>
      _FloatingGlassSwitchButtonState();
}

class _FloatingGlassSwitchButtonState extends State<FloatingGlassSwitchButton> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final base = size.longestSide;

    final double trackWidth = base * 0.08;
    final double trackHeight = base * 0.04;
    final double handleSize = trackHeight * 0.4;
    final double fontSize = base * 0.02;

    String displayText = widget.value ? "TM" : "SW";

    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: Container(
        width: trackWidth, // 💡 비율 적용!
        height: trackHeight, // 💡 비율 적용!
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 231, 231, 231),
          borderRadius: BorderRadius.circular(
            trackHeight / 2,
          ), // 트랙 높이의 절반을 주면 항상 완벽한 알약 모양이 됩니다
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: widget.value
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Padding(
                // 💡 글자 위치도 트랙 크기에 비례해서 밀어줍니다
                padding: widget.value
                    ? EdgeInsets.only(left: trackWidth * 0.15)
                    : EdgeInsets.only(right: trackWidth * 0.15),
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: const Color.fromARGB(240, 121, 121, 121),
                    fontSize: fontSize, // 💡 글자 크기 비율 적용!
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: widget.value
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: handleSize, // 💡 동그라미 가로 비율 적용!
                  height: handleSize, // 💡 동그라미 세로 비율 적용!
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(240, 121, 121, 121),
                    shape: BoxShape.circle,
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

// =========================================================
// 5. 시계 디자인
// =========================================================
class SharedClockPainter extends CustomPainter {
  final double drawnSeconds;
  final double maxScaleSeconds;
  final bool isTimer;
  final String indicatorMode;

  // 기본값을 설정해둡니다.
  SharedClockPainter(
    this.drawnSeconds,
    this.maxScaleSeconds, {
    this.isTimer = true,
    this.indicatorMode = "number",
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // final radius = size.width / 2;
    final radius = min(size.width, size.height) * 0.5;

    // 빨간색 부채꼴 크기
    final sweepAngle = (drawnSeconds / maxScaleSeconds) * 2 * pi;

    double startAngle;
    if (isTimer) {
      startAngle =
          -pi / 2 +
          ((maxScaleSeconds - drawnSeconds) / maxScaleSeconds) * 2 * pi;
    } else {
      startAngle = -pi / 2;
    }

    final paintArc = Paint()
      ..color = globalClockColor.value
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
      ..color = globalIndicatorColor.value.withOpacity(0.5)
      ..strokeWidth =
          2.0 // 두꺼움
      ..strokeCap = StrokeCap.round; // 선 끝 동그랗게

    final fiveTickPaint = Paint()
      ..color = globalIndicatorColor.value.withOpacity(0.5)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round; // 선 끝 동그랗게

    for (int t = 0; t < 60; t++) {
      final angle = (t / 60) * 2 * pi - pi / 2;
      bool isFiveMinute = t % 5 == 0;
      Paint currentPaint = isFiveMinute ? fiveTickPaint : tickPaint;
      double innerRadiusRatio = isFiveMinute ? 0.92 : 0.96;

      canvas.drawLine(
        center +
            Offset(
              cos(angle) * (radius * innerRadiusRatio),
              sin(angle) * (radius * innerRadiusRatio),
            ),
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
        final dotPaint = Paint()
          ..color = const Color.fromARGB(255, 121, 121, 121)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), radius * 0.03, dotPaint);
      } else if (indicatorMode == "number") {
        // [숫자 모드]
        textPainter.text = TextSpan(
          text: '$i',
          style: TextStyle(
            fontSize: relativeFontSize,
            color: globalIndicatorColor.value,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
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
        crossAxisAlignment: CrossAxisAlignment.center, // 네모 점들이 수직 중앙에 잘 오도록 정렬
        children: timeString.split('').map((char) {
          // 👇👇👇 콜론(:)을 텍스트 대신 완벽한 네모 점으로 교체! 👇👇👇
          if (char == ':') {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
              ), // 숫자와 점 사이 여백
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: fontSize * 0.12, // 점의 너비
                    height: fontSize * 0.12, // 점의 높이 (너비와 같게 해서 정사각형)
                    decoration: BoxDecoration(
                      color: Colors.black, // 점 색상
                      borderRadius: BorderRadius.circular(
                        1.0,
                      ), // 너무 날카롭지 않게 모서리만 살짝 깎음
                    ),
                  ),
                  SizedBox(height: fontSize * 0.25), // 위 점과 아래 점 사이의 간격
                  Container(
                    width: fontSize * 0.12,
                    height: fontSize * 0.12,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(1.0),
                    ),
                  ),
                ],
              ),
            );
          }
          // 💡 복잡했던 코드 대신 한 줄로 해결!
          return ClassicFlipDigit(digit: char, fontSize: fontSize);
        }).toList(),
      );
    } else if (styleMode == "segment") {
      // 📟 [전자시계 세그먼트 스타일]
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: timeString.split('').map((char) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0), // 숫자 사이 간격
            child: SevenSegmentDigit(
              digit: char,
              height: fontSize * 0.9, // 폰트 크기를 높이로 변환
              color: defaultColor, // 빨간색, 검은색 등 현재 테마 색상 자동 적용
            ),
          );
        }).toList(),
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
  const ClassicFlipDigit({
    super.key,
    required this.digit,
    required this.fontSize,
  });

  @override
  State<ClassicFlipDigit> createState() => _ClassicFlipDigitState();
}

class _ClassicFlipDigitState extends State<ClassicFlipDigit>
    with SingleTickerProviderStateMixin {
  late String _currentDigit;
  late String _nextDigit;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _currentDigit = widget.digit;
    _nextDigit = widget.digit;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              topHalf,
              Container(
                height: 2.0,
                width: widget.fontSize * 0.7,
                color: Colors.black87,
              ), // 절취선
              bottomHalf,
            ],
          ),
        );
      },
    );
  }
}

// =========================================================
// 🌟 찐 7-세그먼트 LED 디스플레이 위젯 (사진과 똑같은 스타일!)
// =========================================================
class SevenSegmentDigit extends StatelessWidget {
  final String digit;
  final double height;
  final Color color;

  const SevenSegmentDigit({
    super.key,
    required this.digit,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 콜론(:) 처리
    if (digit == ':') {
      return Transform(
        transform: Matrix4.skewX(-0.15), // 💡 1. 숫자와 똑같이 기울어지게 만듭니다!
        child: SizedBox(
          width: height * 0.25,
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 💡 2. 동그라미(BoxShape.circle)를 지우고 네모 모양으로 바꿨습니다.
              Container(
                width: height * 0.1,
                height: height * 0.1,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(
                    1.5,
                  ), // 모서리가 너무 날카롭지 않게 살짝만 둥글림
                ),
              ),
              Container(
                width: height * 0.1,
                height: height * 0.1,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 각 숫자별로 어떤 막대기가 켜져야 하는지 정의 (A~G 7개 막대기)
    final bool a = [
      '0',
      '2',
      '3',
      '5',
      '6',
      '7',
      '8',
      '9',
    ].contains(digit); // 맨 위
    final bool b = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '7',
      '8',
      '9',
    ].contains(digit); // 우측 상단
    final bool c = [
      '0',
      '1',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
    ].contains(digit); // 우측 하단
    final bool d = ['0', '2', '3', '5', '6', '8', '9'].contains(digit); // 맨 아래
    final bool e = ['0', '2', '6', '8'].contains(digit); // 좌측 하단
    final bool f = ['0', '4', '5', '6', '8', '9'].contains(digit); // 좌측 상단
    final bool g = ['2', '3', '4', '5', '6', '8', '9'].contains(digit); // 가운데

    double w = height * 0.55; // 숫자 하나의 너비 비율
    double t = height * 0.18; // LED 막대기의 두께
    double gap = height * 0.05; // 막대 사이 틈

    // 막대기 1개를 그리는 함수
    Widget segment(bool active) {
      return Container(
        // 막대 사이틈
        margin: EdgeInsets.all(gap),
        decoration: BoxDecoration(
          color: active
              ? color
              : color.withOpacity(0.08), // 💡 꺼진 막대기도 희미하게 보여서 진짜 LCD 느낌 냄!
          borderRadius: BorderRadius.circular(t / 2),
        ),
      );
    }

    return Transform(
      transform: Matrix4.skewX(-0.15), // 💡 전자시계 특유의 살짝 기울어진(Italic) 감성 추가!
      child: SizedBox(
        width: w,
        height: height,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: t * 0.4,
              right: t * 0.4,
              height: t,
              child: segment(a),
            ), // A
            Positioned(
              top: t * 0.5,
              right: 0,
              width: t,
              height: height / 2 - t * 0.5,
              child: segment(b),
            ), // B
            Positioned(
              bottom: t * 0.5,
              right: 0,
              width: t,
              height: height / 2 - t * 0.5,
              child: segment(c),
            ), // C
            Positioned(
              bottom: 0,
              left: t * 0.4,
              right: t * 0.4,
              height: t,
              child: segment(d),
            ), // D
            Positioned(
              bottom: t * 0.5,
              left: 0,
              width: t,
              height: height / 2 - t * 0.5,
              child: segment(e),
            ), // E
            Positioned(
              top: t * 0.5,
              left: 0,
              width: t,
              height: height / 2 - t * 0.5,
              child: segment(f),
            ), // F
            Positioned(
              top: height / 2 - t / 2,
              left: t * 0.4,
              right: t * 0.4,
              height: t,
              child: segment(g),
            ), // G
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 🌟 [공통 시계 레이아웃] 타이머와 스탑워치의 겹치는 디자인을 하나로 합침!
// =========================================================
typedef ClockPanCallback = void Function(Offset localPosition, Size size);

class BaseClockLayout extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onTapToggle; // 화면 터치 시 시작/멈춤

  // 드래그 조작 관련 콜백
  final VoidCallback? onPanStart;
  final ClockPanCallback? onPanUpdate;
  final VoidCallback? onPanEnd;

  // 시계 렌더링 값
  final double drawnSeconds;
  final double maxScaleSeconds;
  final bool isTimer;
  final double digitalSeconds;

  const BaseClockLayout({
    super.key,
    required this.isRunning,
    required this.onTapToggle,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    required this.drawnSeconds,
    required this.maxScaleSeconds,
    required this.isTimer,
    required this.digitalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final clockSize =
            min(constraints.maxWidth, constraints.maxHeight) * 0.7;
        final digitalFontSize = availableHeight * 0.07;

        return AnimatedBuilder(
          animation: Listenable.merge([
            globalDisplayMode,
            globalIndicatorMode,
            globalDigitalStyle,
            globalClockColor,
            globalDigitalColor,
            globalIndicatorColor,
          ]),
          builder: (context, child) {
            String displayMode = globalDisplayMode.value;
            String indicatorMode = globalIndicatorMode.value;
            String digitalStyle = globalDigitalStyle.value;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapToggle,
              child: Stack(
                children: [
                  Align(
                    alignment: const Alignment(0, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 1. 아날로그 시계 영역
                        if (displayMode == "both" || displayMode == "analog")
                          GestureDetector(
                            // 받아온 함수가 있으면 실행하고, 없으면 무시(null)
                            onPanStart: onPanStart != null
                                ? (_) => onPanStart!()
                                : null,
                            onPanUpdate: onPanUpdate != null
                                ? (details) => onPanUpdate!(
                                    details.localPosition,
                                    Size(clockSize, clockSize),
                                  )
                                : null,
                            onPanEnd: onPanEnd != null
                                ? (_) => onPanEnd!()
                                : null,

                            child: CustomPaint(
                              size: Size(clockSize, clockSize),
                              painter: SharedClockPainter(
                                drawnSeconds,
                                maxScaleSeconds,
                                isTimer: isTimer,
                                indicatorMode: indicatorMode,
                              ),
                            ),
                          ),

                        // 2. 중간 여백
                        if (displayMode == "both")
                          SizedBox(height: availableHeight * 0.08),

                        // 3. 디지털 텍스트 영역
                        if (displayMode == "both" || displayMode == "digital")
                          CustomDigitalClock(
                            seconds: digitalSeconds,
                            styleMode: digitalStyle,
                            fontSize: digitalFontSize,
                            defaultColor: globalDigitalColor.value,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:math' as math;

class TutorialOverlayWidget extends StatelessWidget {
  final int step;
  final VoidCallback onTap;

  const TutorialOverlayWidget({
    super.key,
    required this.step,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    String title = "";
    String desc = "";
    Alignment align = Alignment.center;
    String arrowDir = "none";
    EdgeInsets padding = EdgeInsets.zero;
 Widget? specialEffectWidget;

    // 단계별 반응형 설정
    switch (step) {
      case 1:
      case 2:
        title = "드래그해서 시간 설정";
        desc = step == 1 
            ? "둥근 시계를 손가락으로 드래그하여\n원하는 시간을 조절하세요."
            : "이런 식으로 시간이 맞춰집니다!";
        if (isLandscape) {
          align = const Alignment(0.8, 0.0);
          arrowDir = "left";
          padding = const EdgeInsets.only(right: 20);
        } else {
          align = const Alignment(0, 0.55);
          arrowDir = "up";
          padding = const EdgeInsets.symmetric(horizontal: 20);
        }
        break;
      case 3:
        title = "터치해서 시작 / 정지";
        desc = "화면 빈 공간을 가볍게 터치하면\n타이머가 바로 시작되거나 멈춥니다.";
        align = isLandscape ? const Alignment(0.8, 0.4) : const Alignment(0, 0.7);
        padding = isLandscape ? const EdgeInsets.only(right: 20) : const EdgeInsets.symmetric(horizontal: 20);
        arrowDir = "none";
        specialEffectWidget = const TouchEffectWidget(); // 💡 터치 이펙트 추가!
        break;
      case 4:
        title = "완료 알림";
        desc = "시간이 0초가 되면 알림이 울립니다.\n설정에서 소리나 진동을 바꿀 수 있어요.";
        align = isLandscape ? const Alignment(0.8, 0.4) : const Alignment(0, 0.7);
        padding = isLandscape ? const EdgeInsets.only(right: 20) : const EdgeInsets.symmetric(horizontal: 20);
        arrowDir = "none";
        break;
              case 5: // ★ 새로 추가된 케이스 (리셋 스와이프 안내)
        title = "타이머 리셋";
        desc = "배경을 아래로 스와이프 하면\n설정 시간으로 리셋 됩니다.";
        if (isLandscape) {
          align = const Alignment(0.8, 0.0);
          arrowDir = "left";
          padding = const EdgeInsets.only(right: 20);
        } else {
          align = const Alignment(0, 0.3); // 화면 중앙에서 약간 아래
          arrowDir = "right"; // 말풍선 꼬리를 오른쪽으로
          padding = const EdgeInsets.symmetric(horizontal: 20);
        }
        specialEffectWidget = const SwipeDownEffectWidget(); // 💡 스와이프 이펙트 추가!
        break;
      case 6:
        // 🔥 [수정] 디지털 숫자를 가리지 않도록 말풍선을 위로 올리고 아래를 가리키게 함
        title = "시간 직접 입력";
        desc = "디지털 숫자를 길게 꾹~ 누르면\n 직접 입력할 수 있어요.";
        if (isLandscape) {
          align = const Alignment(-0.8, 0);
          arrowDir = "right";
          padding = const EdgeInsets.only(right: 20);
        } else {
          align = const Alignment(0, 0.10); // 화면 중앙보다 살짝 위
          arrowDir = "down"; // 아래(디지털 숫자 방향)를 가리킴
          padding = const EdgeInsets.symmetric(horizontal: 20);
        }
        break;
      case 7:
        title = "화면 잠금 켜기";
        desc = "빈 배경을 꾹~ 누르면 잠금 모드가 켜져서\n실수로 터치되는 것을 막아줍니다.";
        align = Alignment.center;
        padding = const EdgeInsets.symmetric(horizontal: 20);
        arrowDir = "none";
        break;
      case 8:
        title = "화면 잠금 해제";
        desc = "다시 한번 배경을 꾹~ 누르면\n잠금 모드가 해제됩니다.";
        align = Alignment.center;
        padding = const EdgeInsets.symmetric(horizontal: 20);
        arrowDir = "none";
        break;
      case 9:
        title = "다양한 설정과 테마";
        desc = "왼쪽 위 메뉴 버튼을 눌러보세요.\n나만의 테마와 알람 설정을 할 수 있어요!";
        align = Alignment.topLeft;
        padding = EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 60,
          left: 20,
        );
        arrowDir = "up_left";
        break;
    }

    // 말풍선 본체
    Widget bubbleContent = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 185, 70, 70),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              "터치해서 다음 ➔",
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );

    // 화살표 방향 로직 조립
    Widget tooltipWidget;
    if (arrowDir == "up" || arrowDir == "up_left") {
      tooltipWidget = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: arrowDir == "up_left" ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(left: arrowDir == "up_left" ? 12 : 0),
            child: const Icon(Icons.arrow_drop_up, color: Colors.white, size: 40),
          ),
          bubbleContent,
        ],
      );
    } else if (arrowDir == "down") {
      // 🔥 [추가] 아래쪽을 가리키는 화살표 로직 추가
      tooltipWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          bubbleContent,
          const Icon(Icons.arrow_drop_down, color: Colors.white, size: 40),
        ],
      );
    } else if (arrowDir == "left") {
      tooltipWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotatedBox(quarterTurns: 3, child: const Icon(Icons.arrow_drop_up, color: Colors.white, size: 40)),
          Flexible(child: bubbleContent),
        ],
      );
    } 
    else if (arrowDir == "right") {
      tooltipWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: bubbleContent),
          RotatedBox(quarterTurns: 1, child: const Icon(Icons.arrow_drop_up, color: Colors.white, size: 40)),
        ],
      );
    }else {
      tooltipWidget = bubbleContent;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Stack(
          children: [
            if (step == 7 || step == 8)
              Positioned(
                top: MediaQuery.of(context).padding.top + 15,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                  child: Icon(step == 7 ? Icons.lock : Icons.lock_open, color: Colors.white, size: 24),
                ),
              ),
                          // ★ 2. 여기에 특수효과 위젯 추가! ★
            if (specialEffectWidget != null) specialEffectWidget!,
            Align(
              alignment: align,
              child: Padding(
                padding: padding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isLandscape ? size.width * 0.45 : 340),
                  child: tooltipWidget,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 여기서부터 파일 맨 아래에 추가 ---

// 1. 터치 특수효과 위젯 (Case 3용)
class TouchEffectWidget extends StatefulWidget {
  const TouchEffectWidget({Key? key}) : super(key: key);
  @override
  _TouchEffectWidgetState createState() => _TouchEffectWidgetState();
}
class _TouchEffectWidgetState extends State<TouchEffectWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Positioned(
      top: isLandscape ? 40 : 120, // 가로모드면 위쪽 가운데쯤, 세로면 배경 위쪽
      right: isLandscape ? MediaQuery.of(context).size.width / 2 - 25 : 50,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Opacity(
            opacity: 1.0 - _ctrl.value,
            child: Container(
              width: 50 + (20 * _ctrl.value),
              height: 50 + (20 * _ctrl.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.5),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(child: Icon(Icons.touch_app, color: Colors.white, size: 30)),
            ),
          );
        },
      ),
    );
  }
}

// 2. 아래로 스와이프 특수효과 위젯 (새로운 Case 5용)
class SwipeDownEffectWidget extends StatefulWidget {
  const SwipeDownEffectWidget({Key? key}) : super(key: key);
  @override
  _SwipeDownEffectWidgetState createState() => _SwipeDownEffectWidgetState();
}
class _SwipeDownEffectWidgetState extends State<SwipeDownEffectWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Positioned(
      top: isLandscape ? 60 : 150, 
      right: isLandscape ? MediaQuery.of(context).size.width / 4 : 60, // 가로모드면 오른쪽에서 1/4 지점쯤에 표시
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 100 * _ctrl.value), // 위에서 아래로 100픽셀 이동
            child: Opacity(
              opacity: 1.0 - _ctrl.value, // 내려가면서 투명해짐
              child: const Icon(Icons.swipe_down, color: Colors.white, size: 50),
            ),
          );
        },
      ),
    );
  }
}
// --- 여기까지 ---

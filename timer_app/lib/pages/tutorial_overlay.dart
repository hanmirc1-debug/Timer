import 'package:flutter/material.dart';

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
        break;
      case 4:
        title = "완료 알림";
        desc = "시간이 0초가 되면 알림이 울립니다.\n설정에서 소리나 진동을 바꿀 수 있어요.";
        align = isLandscape ? const Alignment(0.8, 0.4) : const Alignment(0, 0.7);
        padding = isLandscape ? const EdgeInsets.only(right: 20) : const EdgeInsets.symmetric(horizontal: 20);
        arrowDir = "none";
        break;
      case 5:
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
      case 6:
        title = "화면 잠금 켜기";
        desc = "빈 배경을 꾹~ 누르면 잠금 모드가 켜져서\n실수로 터치되는 것을 막아줍니다.";
        align = Alignment.center;
        padding = const EdgeInsets.symmetric(horizontal: 20);
        arrowDir = "none";
        break;
      case 7:
        title = "화면 잠금 해제";
        desc = "다시 한번 배경을 꾹~ 누르면\n잠금 모드가 해제됩니다.";
        align = Alignment.center;
        padding = const EdgeInsets.symmetric(horizontal: 20);
        arrowDir = "none";
        break;
      case 8:
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
            if (step == 6 || step == 7)
              Positioned(
                top: MediaQuery.of(context).padding.top + 15,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                  child: Icon(step == 6 ? Icons.lock : Icons.lock_open, color: Colors.white, size: 24),
                ),
              ),
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
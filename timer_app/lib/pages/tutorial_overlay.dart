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
    
    Widget? specialEffectWidget;
    Alignment effectAlign = const Alignment(0, 0);

    // 단계별 반응형 설정
    switch (step) {
      case 1:
      case 2:
        title = "드래그해서 시간 설정";
        desc = step == 1 
            ? "시계를 드래그하여 시간을 조절하세요."
            : "이렇게 시간이 맞춰집니다!";
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
        specialEffectWidget = const TouchEffectWidget();
        // ★ 터치 이펙트 위치 지정
        effectAlign = isLandscape ? const Alignment(0.0, -0.8) : const Alignment(0.7, -0.8);
        break;
      case 4:
        title = "완료 알림";
        desc = "시간이 0초가 되면 알림이 울립니다.\n설정에서 소리나 진동을 바꿀 수 있어요.";
        align = isLandscape ? const Alignment(0.8, 0.4) : const Alignment(0, 0.7);
        padding = isLandscape ? const EdgeInsets.only(right: 20) : const EdgeInsets.symmetric(horizontal: 20);
        arrowDir = "none";
        break;
      case 5:
        title = "타이머 리셋";
        desc = "배경을 아래로 스와이프 하면\n설정 시간으로 리셋 됩니다.";
        if (isLandscape) {
          align = const Alignment(0.8, 0.0);
          padding = const EdgeInsets.only(right: 20);
          effectAlign = const Alignment(-0.1, -0.8); // ★ 가로 모드: 스와이프 효과 가운데 위로 이동
        } else {
          align = const Alignment(0, 0.3); // 화면 중앙에서 약간 아래
          padding = const EdgeInsets.symmetric(horizontal: 20);
          effectAlign = const Alignment(0.8, -0.9); // ★ 세로 모드: 스와이프 효과 좀 더 오른쪽 위로 이동
        }
        specialEffectWidget = const SwipeDownEffectWidget();
        break;
      case 6:
        title = "시간 직접 입력";
        desc = "디지털 숫자를 길게 꾹~ 누르면\n 직접 입력할 수 있어요.";
        if (isLandscape) {
          align = const Alignment(-0.8, 0);
          arrowDir = "right";
          padding = const EdgeInsets.only(right: 20);
          effectAlign = const Alignment(0.55, 0.0); // ★ 가로 모드: 특수효과를 우측 디지털 시계 위로 이동
        } else {
          align = const Alignment(0, 0.10); // 화면 중앙보다 살짝 위
          arrowDir = "down"; // 아래(디지털 숫자 방향)를 가리킴
          padding = const EdgeInsets.symmetric(horizontal: 20);
          effectAlign = const Alignment(0.0, 0.6); // ★ 세로 모드: 디지털 시계 위치로 터치 효과 이동
        }
        specialEffectWidget = const TouchEffectWidget(); // 💡 디지털 시계 터치 이펙트 추가!
        break;
      case 7:
        title = "화면 잠금 켜기";
        desc = "빈 배경을 꾹~ 누르면 잠금 모드가 켜져서\n실수로 터치되는 것을 막아줍니다.";
        if (isLandscape) {
        align = Alignment.center;
        padding = const EdgeInsets.symmetric(horizontal: 20);
        arrowDir = "none";
        specialEffectWidget = const TouchEffectWidget();
        effectAlign = const Alignment(-0.1, -0.8); // ★ 세로 모드: 스와이프 효과 좀 더 오른쪽 위로 이
        } else {
        align = Alignment.center;
        padding = const EdgeInsets.symmetric(horizontal: 20);
        arrowDir = "none";
        specialEffectWidget = const TouchEffectWidget();
        effectAlign = const Alignment(0.8, -0.9); // ★ 세로 모드: 스와이프 효과 좀 더 오른쪽 위로 이
        }
        break;
      case 8:
        title = "화면 잠금 해제";
        desc = "다시 한번 배경을 꾹~ 누르면\n잠금 모드가 해제됩니다.";
        if (isLandscape) {
        align = Alignment.center;
        padding = const EdgeInsets.symmetric(horizontal: 20);
        arrowDir = "none";
        specialEffectWidget = const TouchEffectWidget();
        effectAlign = const Alignment(-0.1, -0.8); // ★ 세로 모드: 스와이프 효과 좀 더 오른쪽 위로 이
        } else {
        align = Alignment.center;
        padding = const EdgeInsets.symmetric(horizontal: 20);
        arrowDir = "none";
        specialEffectWidget = const TouchEffectWidget();
        effectAlign = const Alignment(0.8, -0.9); // ★ 세로 모드: 스와이프 효과 좀 더 오른쪽 위로 이
        }
        break;
case 9:
        title = "설정";
        desc = "왼쪽 위 메뉴 버튼을 눌러보세요.\n나만의 테마와 알람 설정등..을 할 수 있어요!";
        
        // 🔥 태블릿/스마트폰 대응을 위한 세밀한 위치 조정
        if (isLandscape) {
          // 가로모드일 때 메뉴 버튼 위치로 조정
          align = const Alignment(-0.95, -0.85); 
          padding = const EdgeInsets.only(top: 20, left: 10);
          arrowDir = "up_left";
        } else {
          // 세로모드일 때 메뉴 버튼 위치로 조정
          align = const Alignment(-0.9, -0.85); 
          padding = EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
          );
          arrowDir = "up_left";
        }
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
    } else if (arrowDir == "right") {
      tooltipWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: bubbleContent),
          RotatedBox(quarterTurns: 1, child: const Icon(Icons.arrow_drop_up, color: Colors.white, size: 40)),
        ],
      );
    } else {
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
            
            // ★ 2. 여기에 특수효과 위젯 추가! (Positioned 대신 effectAlign을 이용한 반응형 정렬)
            if (specialEffectWidget != null)
              Align(
                alignment: effectAlign,
                child: specialEffectWidget,
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

// --- 특수효과 위젯 (Positioned 제거 및 순수 애니메이션만 반환하도록 수정) ---

// 1. 터치 특수효과 위젯
class TouchEffectWidget extends StatefulWidget {
  const TouchEffectWidget({super.key});
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
  void dispose() { 
    _ctrl.dispose(); 
    super.dispose(); 
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
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
    );
  }
}

// 2. 아래로 스와이프 특수효과 위젯
class SwipeDownEffectWidget extends StatefulWidget {
  const SwipeDownEffectWidget({super.key});
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
  void dispose() { 
    _ctrl.dispose(); 
    super.dispose(); 
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
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
    );
  }
}
import 'package:flutter/material.dart';
// 👇 전역 변수(globalDisplayMode 등)를 가져오기 위해 shared_design을 불러옵니다!
import '../pages/shared_design.dart'; // (경로는 프로젝트 구조에 맞게 수정하세요)

class ClockSettingPopup extends StatefulWidget {
  const ClockSettingPopup({super.key});

  @override
  State<ClockSettingPopup> createState() => _ClockSettingPopupState();
}

class _ClockSettingPopupState extends State<ClockSettingPopup> {
  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return Center(
      child: Material(
        borderRadius: BorderRadius.circular(20),
        elevation: 10,
        child: Container(
          width: screen.width * 0.4,
          height: screen.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // 1. 고정 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black12)),
                ),
                child: const Text(
                  "시계 설정",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              // 2. 스크롤 본문
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimatedBuilder(
                    // 👇 shared_design에 있는 전역 변수를 감지합니다.
                    // 아래여기에 넣어야 선택 칸이 칠해짐.
                    animation: Listenable.merge([
                      globalDisplayMode,
                      globalIndicatorMode,
                      globalDigitalStyle,
                    ]),
                    builder: (context, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "표시 방식",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          RadioListTile<String>(
                            title: const Text("둘 다 표시 (기본)"),
                            value: "both",
                            groupValue: globalDisplayMode.value,
                            onChanged: (val) => globalDisplayMode.value = val!,
                          ),
                          RadioListTile<String>(
                            title: const Text("아날로그 시계만"),
                            value: "analog",
                            groupValue: globalDisplayMode.value,
                            onChanged: (val) => globalDisplayMode.value = val!,
                          ),
                          RadioListTile<String>(
                            title: const Text("디지털 시계만"),
                            value: "digital",
                            groupValue: globalDisplayMode.value,
                            onChanged: (val) => globalDisplayMode.value = val!,
                          ),
                          const Divider(height: 30),
                          const Text(
                            "눈금 스타일",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          RadioListTile<String>(
                            title: const Text("점으로 표시 (기본)"),
                            value: "dot",
                            groupValue: globalIndicatorMode.value,
                            onChanged: (val) =>
                                globalIndicatorMode.value = val!,
                          ),
                          RadioListTile<String>(
                            title: const Text("숫자로 표시"),
                            value: "number",
                            groupValue: globalIndicatorMode.value,
                            onChanged: (val) =>
                                globalIndicatorMode.value = val!,
                          ),
                          const Divider(height: 30),

                          // 👇 2. 새로 추가되는 디지털 폰트 스타일 영역!
                          const Text(
                            "디지털 폰트 스타일",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          RadioListTile<String>(
                            title: const Text("기본 둥근 스타일"),
                            value: "default",
                            groupValue: globalDigitalStyle.value,
                            onChanged: (val) => globalDigitalStyle.value = val!,
                          ),
                          RadioListTile<String>(
                            title: const Text("전자시계 (세그먼트)"),
                            value: "segment",
                            groupValue: globalDigitalStyle.value,
                            onChanged: (val) => globalDigitalStyle.value = val!,
                          ),
                          RadioListTile<String>(
                            title: const Text("플립 시계 (달력형)"),
                            value: "flip",
                            groupValue: globalDigitalStyle.value,
                            onChanged: (val) => globalDigitalStyle.value = val!,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

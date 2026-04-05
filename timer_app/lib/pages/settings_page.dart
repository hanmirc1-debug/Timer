import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // iOS 스타일 휠 피커용
import 'package:timer_app/pages/shared_design.dart'; 
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/gestures.dart'; // 💡 마우스 드래그를 허용하기 위해 꼭 추가!

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> _tabTitles = [
    "계정 설정", "즐겨 찾기", "테마", "시계 설정", "알림 설정", "BGM", "고객 센터",
  ];

  late List<GlobalKey> _sectionKeys;
  int _selectedIndex = 0;

  final ScrollController _scrollController = ScrollController();
  bool _isTappingTab = false;

  @override
  void initState() {
    super.initState();
    _sectionKeys = List.generate(_tabTitles.length, (index) => GlobalKey());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isTappingTab) return;
    int newIndex = _selectedIndex;
    double triggerLine = 200.0;

    for (int i = 0; i < _sectionKeys.length; i++) {
      final context = _sectionKeys[i].currentContext;
      if (context != null) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        if (position.dy <= triggerLine) newIndex = i;
      }
    }
    if (newIndex != _selectedIndex) {
      setState(() => _selectedIndex = newIndex);
    }
  }

  void _scrollToSection(int index) async {
    setState(() {
      _selectedIndex = index;
      _isTappingTab = true;
    });
    final context = _sectionKeys[index].currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        alignment: 0.0,
      );
    }
    await Future.delayed(const Duration(milliseconds: 50));
    _isTappingTab = false;
  }

  Widget colorPicker(String title, ValueNotifier<Color> notifier) {
    return ValueListenableBuilder<Color>(
      valueListenable: notifier,
      builder: (context, color, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) {
                    Color tempColor = notifier.value;
                    return StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return AlertDialog(
                          content: BlockPicker(
                            pickerColor: tempColor,
                            onColorChanged: (c) {
                              setStateDialog(() => tempColor = c);
                              notifier.value = c; 
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        );
      },
    );
  }

  // 모드 선택 토글 (간격 확 줄임)
  Widget buildTwoOptionToggle(String title, String opt1, String opt2, ValueNotifier<bool> notifier) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, isTrue, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0), // 패딩 제거
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
              CupertinoSlidingSegmentedControl<bool>(
                groupValue: isTrue,
                thumbColor: Colors.white,
                backgroundColor: Colors.grey.shade200,
                children: {
                  true: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text(opt1, style: TextStyle(color: isTrue ? const Color(0xFFD32F2F) : Colors.grey, fontWeight: FontWeight.bold))),
                  false: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text(opt2, style: TextStyle(color: !isTrue ? const Color(0xFFD32F2F) : Colors.grey, fontWeight: FontWeight.bold))),
                },
                onValueChanged: (val) {
                  if (val != null) notifier.value = val;
                }
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // 상단바 영역
            Container(
              color: const Color(0xFFF9F9F9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87), onPressed: () => Navigator.pop(context)),
                        ),
                        const Text("Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: List.generate(_tabTitles.length, (index) {
                        bool isActive = _selectedIndex == index;
                        return GestureDetector(
                          onTap: () => _scrollToSection(index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 20.0),
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              _tabTitles[index],
                              style: TextStyle(fontSize: 16, fontWeight: isActive ? FontWeight.bold : FontWeight.w600, color: isActive ? const Color(0xFFD32F2F) : Colors.grey.shade400),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                ],
              ),
            ),

            // 본문 영역
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: List.generate(_tabTitles.length, (index) {
                    return _buildSectionBox(index);
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionBox(int index) {
    bool isLastItem = index == _tabTitles.length - 1;

    Widget sectionContent;

    if (index == 2) {
      // 테마 설정
      sectionContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          colorPicker("배경색", globalBgColor),
          const SizedBox(height: 8),
          colorPicker("시계색", globalClockColor),
          const SizedBox(height: 8),
          colorPicker("디지털 시계", globalDigitalColor),
          const SizedBox(height: 8),
          colorPicker("테두리/시간", globalIndicatorColor),
        ],
      );
    } else if (index == 3) {
      // 🌟 시계 설정 (옵션들 사이 공간 확 줄였습니다!)
      sectionContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTwoOptionToggle("모드 선택", "Timer", "Stopwatch", globalIsTimerMode),
          Divider(color: Colors.grey.shade200, height: 10, thickness: 1), // 간격 최소화
          
          CustomWheelPicker(title: "시계 표시", options: const ["both", "analog", "digital"], notifier: globalDisplayMode),
          Divider(color: Colors.grey.shade200, height: 10, thickness: 1),
          
          CustomWheelPicker(title: "숫자 표시", options: const ["number", "dot", "none"], notifier: globalIndicatorMode),
          Divider(color: Colors.grey.shade200, height: 10, thickness: 1),
          
          CustomWheelPicker(title: "디지털 스타일", options: const ["default", "segment", "flip"], notifier: globalDigitalStyle),
          Divider(color: Colors.grey.shade200, height: 10, thickness: 1),
          
          CustomWheelPicker(title: "폰트 크기", options: const ["Small", "Medium", "Large"], notifier: globalDigitalFontSize),
          Divider(color: Colors.grey.shade200, height: 10, thickness: 1),
          
          CustomWheelPicker(title: "햅틱 진동", options: const ["None", "Soft", "Medium", "Strong"], notifier: globalHapticIntensity),        ],
      );
    } else {
      sectionContent = Text(
        "${_tabTitles[index]} 설정 내용을 여기에 넣으세요!",
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      );
    }

    return Column(
      key: _sectionKeys[index],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
          child: Text(
            _tabTitles[index],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 박스 여백 최소화
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD32F2F), width: 1.2),
          ),
          child: sectionContent,
        ),
        if (!isLastItem)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Color(0xFFE0E0E0), thickness: 1.0, indent: 30.0, endIndent: 30.0),
          ),
      ],
    );
  }
}
// =========================================================
// 🌟 마우스 드래그 스크롤까지 완벽하게 먹히는 휠 피커!
// =========================================================
class CustomWheelPicker extends StatefulWidget {
  final String title;
  final List<String> options;
  final ValueNotifier<String> notifier;

  const CustomWheelPicker({super.key, required this.title, required this.options, required this.notifier});

  @override
  State<CustomWheelPicker> createState() => _CustomWheelPickerState();
}

class _CustomWheelPickerState extends State<CustomWheelPicker> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    int initialIndex = widget.options.indexOf(widget.notifier.value);
    if (initialIndex == -1) initialIndex = 0;
    _controller = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.title, style: const TextStyle(fontSize: 16, color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
          SizedBox(
            width: 140,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. 뒤에 깔리는 선택된 항목 회색 배경
                Container(
                  width: 120,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                
                // 👇👇👇 핵심 해결: 마우스 드래그를 강제로 허용하는 설정 덮어씌우기! 👇👇👇
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch, // 손가락 터치
                      PointerDeviceKind.mouse, // 💡 웹/PC에서 마우스 클릭 후 드래그 허용!
                      PointerDeviceKind.trackpad, // 노트북 트랙패드
                    },
                  ),
                  child: CupertinoPicker(
                    scrollController: _controller,
                    itemExtent: 32.0,
                    diameterRatio: 1.5,
                    selectionOverlay: const SizedBox(), 
                    onSelectedItemChanged: (index) {
                      widget.notifier.value = widget.options[index]; 
                    },
                    children: List<Widget>.generate(widget.options.length, (index) {
                      return Center(
                        child: ValueListenableBuilder<String>(
                          valueListenable: widget.notifier,
                          builder: (context, currentValue, child) {
                            bool isSelected = widget.options[index] == currentValue;
                            return Text(
                              widget.options[index],
                              style: TextStyle(
                                fontSize: isSelected ? 16 : 14, 
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? const Color(0xFFD32F2F) : Colors.red.shade200,
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
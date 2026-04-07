import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:timer_app/pages/shared_design.dart'; // 경로 확인해주세요!
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/gestures.dart'; 

// =========================================================
// 🌟 테마 색상 4개를 묶어주는 캡슐(프리셋 데이터)
// =========================================================
class AppThemePreset {
  final Color bg;         // 배경색
  final Color clock;      // 시계색
  final Color digital;    // 디지털 시계 숫자색
  final Color indicator;  // 테두리/시간(눈금) 색

  const AppThemePreset(this.bg, this.clock, this.digital, this.indicator);
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> _tabTitles = [
    "계정 설정", "즐겨 찾기", "테마", "시계 설정", "알림 설정", "BGM", "고객 센터",
  ];

  // =========================================================
  // 🎨 [정식 테마 프리셋 리스트]
  // =========================================================
  final List<AppThemePreset> _themePresets = [
    // 정현표 디폴트
    const AppThemePreset(Color(0xFF252528), Color.fromARGB(255, 185, 70, 70), Color(0xFFE5E5EA), Color(0xFF8E8E93)),
    // 1. 다크 모드 매트
    const AppThemePreset(Color(0xFF252528), Color(0xFF4A4A4D), Color(0xFFE5E5EA), Color(0xFF8E8E93)),
    // 2. 애플 레드 
    const AppThemePreset(Color(0xFFF9F9F9), Color(0xFFD32F2F), Color(0xFF1C1C1E), Color(0xFFD32F2F)),
    // 3. 네이비 블루 
    const AppThemePreset(Color(0xFF1C2536), Color(0xFF2D3C5A), Color(0xFFFFFFFF), Color(0xFF8B9BB4)),
    // 4. 포레스트 그린
    const AppThemePreset(Color(0xFF1E2E26), Color(0xFF334A3E), Color(0xFFE2E8E4), Color(0xFF88A094)),
    // 5. 따뜻한 베이지
    const AppThemePreset(Color(0xFFF4EFE6), Color(0xFFD1C2A5), Color(0xFF5C4E3A), Color(0xFF9E8E76)),
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

  // 💡 accentColor를 파라미터로 받아서 색상 적용!
  Widget colorPicker(String title, ValueNotifier<Color> notifier, Color accentColor) {
    return ValueListenableBuilder<Color>(
      valueListenable: notifier,
      builder: (context, color, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 💡 여기 글자색을 accentColor로 연동했습니다!
              Text(title, style: TextStyle(fontSize: 16, color: accentColor, fontWeight: FontWeight.bold)),
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
                  width: 36, height: 36, 
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildTwoOptionToggle(String title, String opt1, String opt2, ValueNotifier<bool> notifier, Color accentColor) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, isTrue, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Text(title, style: TextStyle(fontSize: 16, color: accentColor, fontWeight: FontWeight.bold)),
              CupertinoSlidingSegmentedControl<bool>(
                groupValue: isTrue,
                thumbColor: Colors.white,
                backgroundColor: Colors.grey.shade200,
                children: {
                  true: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Text(opt1, style: TextStyle(color: isTrue ? accentColor : Colors.grey, fontWeight: FontWeight.bold))),
                  false: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Text(opt2, style: TextStyle(color: !isTrue ? accentColor : Colors.grey, fontWeight: FontWeight.bold))),
                },
                onValueChanged: (val) {
                  if (val != null) notifier.value = val;
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: globalClockColor,
      builder: (context, accentColor, child) {
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
                              child: IconButton(
                                icon: Icon(Icons.arrow_back_ios_new, color: accentColor), 
                                onPressed: () => Navigator.pop(context)
                              ),
                            ),
                            Text("Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor)), 
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
                                  style: TextStyle(
                                    fontSize: 16, 
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600, 
                                    color: isActive ? accentColor : Colors.grey.shade400 
                                  ),
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
                        return _buildSectionBox(index, accentColor); 
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildSectionBox(int index, Color accentColor) {
    bool isLastItem = index == _tabTitles.length - 1;
    Widget sectionContent;

    if (index == 2) {
      // 🌟 테마 설정 탭
      sectionContent = AnimatedBuilder(
        animation: Listenable.merge([globalBgColor, globalClockColor, globalDigitalColor, globalIndicatorColor]),
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 💡 소제목 글자색도 투명도(0.7)를 준 accentColor로 맞춰 통일감을 줍니다.
              Text("프리셋 선택", style: TextStyle(fontSize: 14, color: accentColor.withOpacity(0.7), fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 12.0, 
                runSpacing: 12.0, 
                children: _themePresets.map((theme) {
                  bool isSelected = globalBgColor.value == theme.bg &&
                                    globalClockColor.value == theme.clock &&
                                    globalDigitalColor.value == theme.digital &&
                                    globalIndicatorColor.value == theme.indicator;
                  return GestureDetector(
                    onTap: () {
                      globalBgColor.value = theme.bg;
                      globalClockColor.value = theme.clock;
                      globalDigitalColor.value = theme.digital;
                      globalIndicatorColor.value = theme.indicator;
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? accentColor : Colors.grey.shade300, 
                          width: isSelected ? 3.0 : 1.0
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.5, 0.5], 
                          colors: [theme.bg, theme.clock],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),
              
              // 💡 소제목 연동
              Text("세부 색상 커스텀", style: TextStyle(fontSize: 14, color: accentColor.withOpacity(0.7), fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // 💡 colorPicker에 accentColor 전달!
              colorPicker("배경색", globalBgColor, accentColor),
              colorPicker("시계색", globalClockColor, accentColor),
              colorPicker("디지털 시계", globalDigitalColor, accentColor),
              colorPicker("테두리/시간", globalIndicatorColor, accentColor),
            ],
          );
        }
      );
    } else if (index == 3) {
      // 🌟 시계 설정 (옵션들)
      sectionContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTwoOptionToggle("모드 선택", "TMR", "SW", globalIsTimerMode, accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),

          CustomWheelPicker(title: "시계 표시", options: const ["both", "analog", "digital"], notifier: globalDisplayMode, accentColor: accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),

          CustomWheelPicker(title: "숫자 표시", options: const ["number", "dot", "none"], notifier: globalIndicatorMode, accentColor: accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),

          CustomWheelPicker(title: "디지털 스타일", options: const ["default", "segment", "flip"], notifier: globalDigitalStyle, accentColor: accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),

          CustomWheelPicker(title: "폰트 크기", options: const ["Small", "Medium", "Large"], notifier: globalDigitalFontSize, accentColor: accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),

          CustomWheelPicker(title: "햅틱 진동", options: const ["None", "Soft", "Medium", "Strong"], notifier: globalHapticIntensity, accentColor: accentColor),
        ],
      );
    } else {
      sectionContent = Text("${_tabTitles[index]} 설정 내용을 여기에 넣으세요!", style: TextStyle(fontSize: 16, color: Colors.black87));
    }

    return Column(
      key: _sectionKeys[index],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
          child: Text(_tabTitles[index], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor)), 
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor, width: 1.2), 
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
// 🌟 CustomWheelPicker
// =========================================================
class CustomWheelPicker extends StatefulWidget {
  final String title;
  final List<String> options;
  final ValueNotifier<String> notifier;
  final Color accentColor; 

  const CustomWheelPicker({super.key, required this.title, required this.options, required this.notifier, required this.accentColor});

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
          Text(widget.title, style: TextStyle(fontSize: 16, color: widget.accentColor, fontWeight: FontWeight.bold)), 
          SizedBox(
            width: 140,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 32,
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                ),
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch, 
                      PointerDeviceKind.mouse, 
                      PointerDeviceKind.trackpad, 
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
                                color: isSelected ? widget.accentColor : widget.accentColor.withOpacity(0.4), 
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
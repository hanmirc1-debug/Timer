import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:timer_app/pages/shared_design.dart'; 
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/gestures.dart'; 
import 'package:flutter/services.dart'; // 💡 진동(Haptic) 기능용
import 'package:audioplayers/audioplayers.dart'; // 💡 오디오 재생 기능용

class AppThemePreset {
  final Color bg;         
  final Color clock;      
  final Color digital;    
  final Color indicator;  

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

  // =========================================================
  // 🌟 오디오 플레이어 및 미리듣기 제어 로직
  // =========================================================
  final AudioPlayer _previewPlayer = AudioPlayer();

  void _stopPreview() {
    // 화면을 터치하면 즉시 재생 중인 소리를 끕니다.
    _previewPlayer.stop();
  }

  Future<void> _playAudio(String fileName) async {
    try {
      // 💡 나중에 'assets/audio/' 폴더를 만들고 여기에 매칭되는 mp3를 넣으시면 됩니다!
      // 파일이 없으면 catch로 빠져서 앱이 죽지 않습니다.
      await _previewPlayer.play(AssetSource('audio/$fileName'));
    } catch (e) {
      debugPrint("오디오 미리듣기 실패 (아직 mp3 파일을 넣지 않았습니다): $e");
    }
  }

  void _previewAlarm(String option) {
    _stopPreview(); // 다른 소리가 나고 있으면 끄기
    if (option == "진동만 (Vibrate)") {
      HapticFeedback.vibrate();
      return;
    }
    
    // 선택된 이름에 맞춰 파일명 지정 (나중에 이 이름으로 mp3를 넣으세요!)
    String fileName = "";
    if (option == "기본음 (Bell)") fileName = "bell.mp3";
    else if (option == "경고음 (Beep)") fileName = "beep.mp3";
    else if (option == "부드러운 (Soft)") fileName = "soft.mp3";
    
    if (fileName.isNotEmpty) _playAudio(fileName);
  }

  void _previewBgm(String option) {
    _stopPreview(); 
    String fileName = "";
    if (option == "백색소음 (White Noise)") fileName = "white_noise.mp3";
    else if (option == "잔잔한 비 (Rain)") fileName = "rain.mp3";
    else if (option == "모닥불 (Fireplace)") fileName = "fireplace.mp3";
    else if (option == "카페 소음 (Cafe)") fileName = "cafe.mp3";
    
    if (fileName.isNotEmpty) _playAudio(fileName);
  }
  // =========================================================

  @override
  void initState() {
    super.initState();
    _sectionKeys = List.generate(_tabTitles.length, (index) => GlobalKey());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _previewPlayer.dispose(); // 💡 페이지 나갈 때 플레이어 메모리 해제
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
    // 🌟 핵심! 가장 바깥쪽을 Listener로 감싸서, 화면 어디든 터치하면 노래가 멈추게 합니다.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _stopPreview(), 
      child: ValueListenableBuilder<Color>(
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
                              Text("SETTINGS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor)), 
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
      ),
    );
  }

  Widget _buildSectionBox(int index, Color accentColor) {
    bool isLastItem = index == _tabTitles.length - 1;
    Widget sectionContent;

    if (index == 2) {
      // 🎨 테마 설정
      sectionContent = AnimatedBuilder(
        animation: Listenable.merge([globalBgColor, globalClockColor, globalDigitalColor, globalIndicatorColor]),
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("프리셋 선택", style: TextStyle(fontSize: 14, color: accentColor.withOpacity(0.7), fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12.0, runSpacing: 12.0, 
                children: _themePresets.map((theme) {
                  bool isSelected = globalBgColor.value == theme.bg && globalClockColor.value == theme.clock && globalDigitalColor.value == theme.digital && globalIndicatorColor.value == theme.indicator;
                  return GestureDetector(
                    onTap: () {
                      globalBgColor.value = theme.bg; globalClockColor.value = theme.clock; globalDigitalColor.value = theme.digital; globalIndicatorColor.value = theme.indicator;
                    },
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? accentColor : Colors.grey.shade300, width: isSelected ? 3.0 : 1.0),
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, stops: const [0.5, 0.5], colors: [theme.bg, theme.clock]),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),
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
      // ⌚ 시계 설정
      sectionContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTwoOptionToggle("모드 선택", "TMR", "SW", globalIsTimerMode, accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(title: "시계 표시", options: const ["BOTH", "ANALOG", "DIGITAL"], notifier: globalDisplayMode, accentColor: accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(title: "숫자 표시", options: const ["NUMBER", "DOT", "NONE"], notifier: globalIndicatorMode, accentColor: accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(title: "디지털 스타일", options: const ["DEFAULT", "SEGMENT", "FLIP"], notifier: globalDigitalStyle, accentColor: accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(title: "폰트 크기", options: const ["SMALL", "MEDIUM", "LARGE"], notifier: globalDigitalFontSize, accentColor: accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          
          // 💡 햅틱 진동 선택 시 실시간으로 진동이 울려볼 수 있게 onSelected 연결
          CustomWheelPicker(
            title: "햅틱 진동", 
            options: const ["NONE", "SOFT", "MEDIUM", "STRONG"], 
            notifier: globalHapticIntensity, 
            accentColor: accentColor,
            onSelected: (val) {
              if (val == "SOFT") HapticFeedback.lightImpact();
              else if (val == "MEDIUM") HapticFeedback.mediumImpact();
              else if (val == "STRONG") HapticFeedback.heavyImpact();
            },
          ),
        ],
      );
    } else if (index == 4) {
      // 🔔 알림 설정
      sectionContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTwoOptionToggle("타이머 종료 알림", "ON", "OFF", globalAlarmEnabled, accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          
          // 💡 알림음 선택 시 미리듣기 재생!
          CustomWheelPicker(
            title: "알림 방식", 
            options: const ["기본음 (Bell)", "경고음 (Beep)", "부드러운 (Soft)", "진동만 (Vibrate)"], 
            notifier: globalAlarmSound, 
            accentColor: accentColor,
            onSelected: (val) => _previewAlarm(val),
          ),
        ],
      );
    } else if (index == 5) {
      // 🎵 BGM 설정
      sectionContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTwoOptionToggle("배경 음악 재생", "ON", "OFF", globalBgmEnabled, accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          
          // 💡 BGM 선택 시 미리듣기 재생!
          CustomWheelPicker(
            title: "트랙 선택", 
            options: const [
              "백색소음 (White Noise)", 
              "잔잔한 비 (Rain)", 
              "모닥불 (Fireplace)", 
              "카페 소음 (Cafe)"
            ], 
            notifier: globalBgmTrack, 
            accentColor: accentColor,
            onSelected: (val) => _previewBgm(val),
          ),
          const SizedBox(height: 12),
          Text(
            "💡 휠을 멈추면 미리듣기가 재생됩니다.\n💡 화면 아무 곳이나 터치하면 재생이 멈춥니다.", 
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)
          ),
        ],
      );
    } else {
      sectionContent = Text("${_tabTitles[index]} 설정 내용을 여기에 넣으세요!", style: const TextStyle(fontSize: 16, color: Colors.black87));
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
// 🌟 CustomWheelPicker (onSelected 파라미터 추가)
// =========================================================
class CustomWheelPicker extends StatefulWidget {
  final String title;
  final List<String> options;
  final ValueNotifier<String> notifier;
  final Color accentColor; 
  final Function(String)? onSelected; // 💡 선택 시 실행할 함수 추가!

  const CustomWheelPicker({
    super.key, 
    required this.title, 
    required this.options, 
    required this.notifier, 
    required this.accentColor,
    this.onSelected,
  });

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
                      
                      // 💡 휠이 특정 항목에 멈추면 미리듣기/진동 함수를 실행합니다!
                      if (widget.onSelected != null) {
                        widget.onSelected!(widget.options[index]);
                      }
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
                                fontSize: isSelected ? 15 : 13,
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
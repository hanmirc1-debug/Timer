import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:timer_app/pages/shared_design.dart';
// 💡 flutter_colorpicker 패키지 제거 완료!
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

// =========================================================
// 🌟 [추가됨] 테마 아이템 모델 (색상인지, 영상인지, 잠겨있는지 구분)
// =========================================================
class ThemeItem {
  final String name;      // 식별용 이름 (예: "빨강", "비 오는 밤")
  final Color? color;     // 단색일 경우 색상값
  final String? video;    // 영상일 경우 식별자
  final bool isLocked;    // 잠금 여부 (나중에 포인트 시스템 연결)

  const ThemeItem({
    required this.name,
    this.color,
    this.video,
    this.isLocked = false, // 기본값은 열려있음
  });
}

class AppThemePreset {
  final Color bg;
  final Color clock;
  final Color digital;
  final Color indicator;
  final String bgVideo; // 💡 프리셋에 비디오 요소 추가!

  const AppThemePreset({
    required this.bg,
    required this.clock,
    required this.digital,
    required this.indicator,
    this.bgVideo = "사용 안 함", // 기본값은 비디오 끄기
  });
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

  final List<AppThemePreset> _themePresets = [
    // 정현표 프리셋
    const AppThemePreset(bg: Color(0xFF252528), clock: Color.fromARGB(255, 185, 70, 70), digital: Color(0xFFE5E5EA), indicator: Color(0xFF8E8E93)),
    const AppThemePreset(bg: Color(0xFF252528), clock: Color(0xFF4A4A4D), digital: Color(0xFFE5E5EA), indicator: Color(0xFF8E8E93)),
    const AppThemePreset(bg: Color(0xFFF9F9F9), clock: Color(0xFFD32F2F), digital: Color(0xFF1C1C1E), indicator: Color(0xFFD32F2F)),
    const AppThemePreset(bg: Color(0xFF1C2536), clock: Color(0xFF2D3C5A), digital: Color(0xFFFFFFFF), indicator: Color(0xFF8B9BB4)),
    const AppThemePreset(bg: Color(0xFF1E2E26), clock: Color(0xFF334A3E), digital: Color(0xFFE2E8E4), indicator: Color(0xFF88A094)),
    const AppThemePreset(bg: Color(0xFFF4EFE6), clock: Color(0xFFD1C2A5), digital: Color(0xFF5C4E3A), indicator: Color(0xFF9E8E76)),
    
    // 💡 [새로 추가됨] 비 오는 밤 영상 프리셋! 
    // (배경은 영상이 보이게 무조건 '회색(Grey)' 톤으로 지정)
    const AppThemePreset(
      bg: Colors.grey, // 무조건 회색!
      clock: Color(0xFF4A6B8C), 
      digital: Colors.white, 
      indicator: Colors.white70,
      bgVideo: "비 오는 밤 (Rain)"
    ),
  ];

  // 💡 스크롤 가능한 예쁜 30여가지 커스텀 팔레트 (ThemeItem으로 변경하여 동영상/잠금 지원!)
  final List<ThemeItem> _backgroundOptions = [
    const ThemeItem(name: "흰색", color: Colors.white),
    ThemeItem(name: "연회색", color: Colors.grey.shade300),
    ThemeItem(name: "회색", color: Colors.grey.shade500),
    ThemeItem(name: "진회색", color: Colors.grey.shade700),
    const ThemeItem(name: "검정", color: Colors.black),
    const ThemeItem(name: "매트 다크", color: Color(0xFF252528)),
    const ThemeItem(name: "애플 블랙", color: Color(0xFF1C1C1E)),
    const ThemeItem(name: "네이비", color: Color(0xFF1C2536)),
    const ThemeItem(name: "포레스트", color: Color(0xFF1E2E26)),
    const ThemeItem(name: "베이지", color: Color(0xFFF4EFE6)),
    const ThemeItem(name: "빨강", color: Colors.red),
    const ThemeItem(name: "체리", color: Color(0xFFD32F2F)),
    const ThemeItem(name: "벽돌", color: Color.fromARGB(255, 185, 70, 70)),
    const ThemeItem(name: "분홍", color: Colors.pink),
    const ThemeItem(name: "보라", color: Colors.purple),
    const ThemeItem(name: "진보라", color: Colors.deepPurple),
    const ThemeItem(name: "인디고", color: Colors.indigo),
    const ThemeItem(name: "파랑", color: Colors.blue),
    const ThemeItem(name: "스틸 블루", color: Color(0xFF4A6B8C)),
    const ThemeItem(name: "연파랑", color: Colors.lightBlue),
    const ThemeItem(name: "청록", color: Colors.cyan),
    const ThemeItem(name: "틸", color: Colors.teal),
    const ThemeItem(name: "초록", color: Colors.green),
    const ThemeItem(name: "딥 그린", color: Color(0xFF334A3E)),
    const ThemeItem(name: "연두", color: Colors.lightGreen),
    const ThemeItem(name: "라임", color: Colors.lime),
    const ThemeItem(name: "노랑", color: Colors.yellow),
    const ThemeItem(name: "호박", color: Colors.amber),
    const ThemeItem(name: "주황", color: Colors.orange),
    const ThemeItem(name: "진주황", color: Colors.deepOrange),
    const ThemeItem(name: "갈색", color: Colors.brown),
    const ThemeItem(name: "모카", color: Color(0xFFD1C2A5)),
    const ThemeItem(name: "커피", color: Color(0xFF5C4E3A)),
    const ThemeItem(name: "투명", color: Colors.transparent),
    
    // 💡 여기에 동영상 옵션도 자연스럽게 끼워 넣을 수 있습니다! (나중에 isLocked: true 만 추가하면 잠금 처리됨)
    const ThemeItem(name: "비 오는 밤", color: Colors.grey, video: "비 오는 밤 (Rain)"),
  ];

  late List<GlobalKey> _sectionKeys;
  late List<GlobalKey> _tabKeys;
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isTappingTab = false;

  void _stopPreview() {
    // 미리듣기 끄기 (AudioPlayer 필요시 추가 구현 가능)
  }

  void _previewAlarm(String option) {
    if (option == "진동만") HapticFeedback.vibrate();
  }

  void _previewBgm(String option) {
    // BGM 미리듣기 로직
  }

  @override
  void initState() {
    super.initState();
    _sectionKeys = List.generate(_tabTitles.length, (index) => GlobalKey());
    _tabKeys = List.generate(_tabTitles.length, (index) => GlobalKey());
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
        if (box.localToGlobal(Offset.zero).dy <= triggerLine) newIndex = i;
      }
    }
    if (newIndex != _selectedIndex) {
      setState(() => _selectedIndex = newIndex);
      _scrollToTabCenter(newIndex);
    }
  }

  void _scrollToSection(int index) async {
    setState(() { _selectedIndex = index; _isTappingTab = true; });
    _scrollToTabCenter(index);
    final context = _sectionKeys[index].currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic, alignment: 0.0);
    }
    await Future.delayed(const Duration(milliseconds: 50));
    _isTappingTab = false;
  }

  void _scrollToTabCenter(int index) {
    final context = _tabKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context, alignment: 0.5, duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubic);
    }
  }

  // =========================================================
  // 🌟 [핵심 변경] 패키지 없이 우리가 직접 만든 커스텀 테마 선택창!
  // =========================================================
  void _showCustomPicker(String title, ValueNotifier<Color> colorNotifier, Color accentColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text("$title 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor)),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, // 한 줄에 5개씩
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _backgroundOptions.length,
                  itemBuilder: (context, index) {
                    final item = _backgroundOptions[index];
                    
                    // 현재 선택된 항목인지 확인
                    bool isSelected = false;
                    if (title == "배경색") {
                      if (item.video != null) {
                        isSelected = globalBgVideoName.value == item.video;
                      } else {
                        isSelected = colorNotifier.value == item.color && globalBgVideoName.value == "사용 안 함";
                      }
                    } else {
                      isSelected = colorNotifier.value == item.color;
                    }

                    // 배경색이 아닌 옵션(시계색 등)을 고를 때는 비디오 전용 아이템을 화면에서 숨깁니다.
                    if (title != "배경색" && item.video != null) return const SizedBox.shrink();

                    return GestureDetector(
                      onTap: () {
                        // 🔒 잠금 기능 로직 (포인트 시스템 추가 시 여기서 차감 팝업 띄우면 됨!)
                        if (item.isLocked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('잠겨있는 테마입니다. (포인트 기능 준비 중)')),
                          );
                          return;
                        }

                        // 🎨 색상 적용
                        if (item.color != null) colorNotifier.value = item.color!;

                        // 🎬 배경색 설정일 경우 비디오 켜고 끄기 연동 처리
                        if (title == "배경색") {
                          if (item.video != null) {
                            globalBgVideoName.value = item.video!; // 비디오 켬
                          } else {
                            globalBgVideoName.value = "사용 안 함"; // 비디오 끔
                          }
                        }

                        Navigator.pop(context); // 창 닫기
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? accentColor : Colors.grey.shade300,
                                width: isSelected ? 3.0 : 1.0,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)
                              ],
                            ),
                          ),
                          // 영상 아이템이면 안에 액자(이미지) 아이콘 표시
                          if (item.video != null)
                            const Icon(Icons.wallpaper, color: Colors.white, size: 20),
                          
                          // 잠겨있으면 반투명 검은 막과 자물쇠 아이콘 표시
                          if (item.isLocked)
                            Container(
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                              child: const Center(child: Icon(Icons.lock, color: Colors.white, size: 20)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget colorPicker(String title, ValueNotifier<Color> notifier, Color accentColor) {
    return ValueListenableBuilder<Color>(
      valueListenable: notifier,
      builder: (context, color, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 16, color: accentColor, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => _showCustomPicker(title, notifier, accentColor), // 💡 패키지 대신 커스텀 창 호출
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color, 
                    borderRadius: BorderRadius.circular(8), 
                    border: Border.all(color: Colors.grey.shade300)
                  ),
                  // 배경색 옵션인데 비디오가 켜져있다면, 현재 상태 박스 안에도 아이콘 표시
                  child: (title == "배경색" && globalBgVideoName.value != "사용 안 함")
                      ? const Icon(Icons.wallpaper, color: Colors.white, size: 20)
                      : null,
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
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<bool>(
                        groupValue: isTrue, thumbColor: Colors.white, backgroundColor: Colors.grey.shade200,
                        children: {
                          true: Container(alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 6), child: Text(opt1, style: TextStyle(color: isTrue ? accentColor : Colors.grey, fontWeight: FontWeight.bold, fontSize: 14))),
                          false: Container(alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 6), child: Text(opt2, style: TextStyle(color: !isTrue ? accentColor : Colors.grey, fontWeight: FontWeight.bold, fontSize: 14))),
                        },
                        onValueChanged: (val) { if (val != null) notifier.value = val; },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                              Align(alignment: Alignment.centerLeft, child: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: accentColor), onPressed: () => Navigator.pop(context))),
                              Text("SETTINGS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor)),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: List.generate(_tabTitles.length, (index) {
                              bool isActive = _selectedIndex == index;
                              return GestureDetector(
                                onTap: () => _scrollToSection(index),
                                child: Container(
                                  key: _tabKeys[index], margin: const EdgeInsets.only(right: 20.0), padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(_tabTitles[index], style: TextStyle(fontSize: 16, fontWeight: isActive ? FontWeight.bold : FontWeight.w600, color: isActive ? accentColor : Colors.grey.shade400)),
                                ),
                              );
                            }),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController, padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(children: List.generate(_tabTitles.length, (index) { return _buildSectionBox(index, accentColor); })),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionBox(int index, Color accentColor) {
    bool isLastItem = index == _tabTitles.length - 1;
    Widget sectionContent;

    if (index == 2) {
      sectionContent = AnimatedBuilder(
        animation: Listenable.merge([globalBgColor, globalClockColor, globalDigitalColor, globalIndicatorColor, globalBgVideoName]),
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("프리셋 선택", style: TextStyle(fontSize: 14, color: accentColor.withOpacity(0.7), fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12.0, runSpacing: 12.0,
                children: _themePresets.map((theme) {
                  // 💡 영상 사용 여부까지 확인해서 겉 테두리에 표시!
                  bool isSelected = globalBgColor.value == theme.bg && globalClockColor.value == theme.clock && globalDigitalColor.value == theme.digital && globalIndicatorColor.value == theme.indicator && globalBgVideoName.value == theme.bgVideo;
                  bool isVideoPreset = theme.bgVideo != "사용 안 함";

                  return GestureDetector(
                    onTap: () {
                      globalBgColor.value = theme.bg;
                      globalClockColor.value = theme.clock;
                      globalDigitalColor.value = theme.digital;
                      globalIndicatorColor.value = theme.indicator;
                      globalBgVideoName.value = theme.bgVideo; // 🔥 비디오도 자동 적용!
                    },
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? accentColor : Colors.grey.shade300, width: isSelected ? 3.0 : 1.0),
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, stops: const [0.5, 0.5], colors: [theme.bg, theme.clock]),
                      ),
                      // 💡 영상 프리셋이면 액자(이미지) 모양 아이콘 표시!
                      child: isVideoPreset ? const Icon(Icons.wallpaper, color: Colors.white, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),
              Text("세부 색상 커스텀", style: TextStyle(fontSize: 14, color: accentColor.withOpacity(0.7), fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              colorPicker("배경색", globalBgColor, accentColor),
              colorPicker("시계색", globalClockColor, accentColor),
              colorPicker("디지털 시계", globalDigitalColor, accentColor),
              colorPicker("테두리/시간", globalIndicatorColor, accentColor),
            ],
          );
        },
      );
    } else if (index == 3) {
      sectionContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTwoOptionToggle("모드 선택", "TMR", "SW", globalIsTimerMode, accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(title: "타이머 최대 눈금", options: const ["30초", "60초 (1분)", "120초 (2분)", "30분", "60분", "120분"], notifier: globalTimerMaxString, accentColor: accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(title: "시계 표시", options: const ["BOTH", "ANALOG", "DIGITAL"], notifier: globalDisplayMode, accentColor: accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(title: "숫자 표시", options: const ["NUMBER", "DOT", "NONE"], notifier: globalIndicatorMode, accentColor: accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(title: "디지털 스타일", options: const ["DEFAULT", "SEGMENT", "FLIP"], notifier: globalDigitalStyle, accentColor: accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(title: "폰트 크기", options: const ["SMALL", "MEDIUM", "LARGE"], notifier: globalDigitalFontSize, accentColor: accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(title: "햅틱 진동", options: const ["NONE", "SOFT", "MEDIUM", "STRONG"], notifier: globalHapticIntensity, accentColor: accentColor),
        ],
      );
    } else if (index == 4) {
      sectionContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTwoOptionToggle("타이머 종료 알림", "ON", "OFF", globalAlarmEnabled, accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(title: "알림 방식", options: const ["기본음", "자전거 벨", "빠른 알림 1", "빠른 알림 2", "신비로운 1", "신비로운 2", "신비로운 3", "심플한 알림 1", "심플한 알림 2", "심플한 알림 3", "심플한 알림 4", "진동만"], notifier: globalAlarmSound, accentColor: accentColor, onSelected: (val) => _previewAlarm(val)),
        ],
      );
    } else if (index == 5) {
      sectionContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTwoOptionToggle("배경 음악 재생", "ON", "OFF", globalBgmEnabled, accentColor),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(title: "트랙 선택", options: const ["백색소음", "잔잔한 비", "모닥불", "카페 소음"], notifier: globalBgmTrack, accentColor: accentColor, onSelected: (val) => _previewBgm(val)),
        ],
      );
    } else {
      sectionContent = Text("${_tabTitles[index]} 설정 내용을 여기에 넣으세요!", style: const TextStyle(fontSize: 16, color: Colors.black87));
    }

    return Column(
      key: _sectionKeys[index], crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 16.0, bottom: 12.0), child: Text(_tabTitles[index], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor))),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: accentColor, width: 1.2)), child: sectionContent),
        if (!isLastItem) const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider(color: Color(0xFFE0E0E0), thickness: 1.0, indent: 30.0, endIndent: 30.0)),
      ],
    );
  }
}

class CustomWheelPicker extends StatefulWidget {
  final String title; final List<String> options; final ValueNotifier<String> notifier; final Color accentColor; final Function(String)? onSelected;
  const CustomWheelPicker({super.key, required this.title, required this.options, required this.notifier, required this.accentColor, this.onSelected});
  @override State<CustomWheelPicker> createState() => _CustomWheelPickerState();
}

class _CustomWheelPickerState extends State<CustomWheelPicker> {
  late FixedExtentScrollController _controller;
  @override void initState() { super.initState(); int initialIndex = widget.options.indexOf(widget.notifier.value); if (initialIndex == -1) initialIndex = 0; _controller = FixedExtentScrollController(initialItem: initialIndex); }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.title, style: TextStyle(fontSize: 16, color: widget.accentColor, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
                child: SizedBox(
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: double.infinity, height: 32, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
                      ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad}),
                        child: CupertinoPicker(
                          scrollController: _controller, itemExtent: 32.0, diameterRatio: 1.5, selectionOverlay: const SizedBox(),
                          onSelectedItemChanged: (index) { widget.notifier.value = widget.options[index]; if (widget.onSelected != null) { widget.onSelected!(widget.options[index]); } },
                          children: List<Widget>.generate(widget.options.length, (index) {
                            return Center(
                              child: ValueListenableBuilder<String>(
                                valueListenable: widget.notifier,
                                builder: (context, currentValue, child) {
                                  bool isSelected = widget.options[index] == currentValue;
                                  return Text(widget.options[index], textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isSelected ? 15 : 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? widget.accentColor : widget.accentColor.withOpacity(0.4)));
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
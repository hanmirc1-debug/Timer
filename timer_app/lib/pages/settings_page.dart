import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 🌟 옵션 제목들 (나중에 여기에 글자만 추가하면 자동으로 기능이 전부 연동됩니다!)
  final List<String> _tabTitles = [
    "계정 설정", 
    "즐겨 찾기", 
    "테마", 
    "시계 설정", 
    "알림 설정", 
    "BGM", 
    "고객 센터"
  ];

  late List<GlobalKey> _sectionKeys;
  int _selectedIndex = 0;
  
  // 💡 스크롤 위치를 감지할 똑똑한 센서 추가!
  final ScrollController _scrollController = ScrollController();
  bool _isTappingTab = false; // 탭을 눌러서 이동 중인지 확인하는 스위치

  @override
  void initState() {
    super.initState();
    _sectionKeys = List.generate(_tabTitles.length, (index) => GlobalKey());
    
    // 센서 가동! 스크롤할 때마다 _onScroll 함수를 실행합니다.
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 페이지 나갈 때 센서도 꺼줍니다.
    super.dispose();
  }

  // 🌟 스크롤을 내리면 현재 위치를 파악해서 상단 탭을 바꿔주는 핵심 함수!
  void _onScroll() {
    if (_isTappingTab) return; // 탭을 직접 눌러서 이동 중일 때는 센서 끄기

    int newIndex = _selectedIndex;
    // 화면 위에서부터 약 200px 지점을 '감지 기준선'으로 잡습니다.
    double triggerLine = 200.0; 

    for (int i = 0; i < _sectionKeys.length; i++) {
      final context = _sectionKeys[i].currentContext;
      if (context != null) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);

        // 해당 섹션의 머리부분(top)이 기준선 위로 올라가면 현재 섹션으로 인정!
        if (position.dy <= triggerLine) {
          newIndex = i;
        }
      }
    }

    // 탭이 바뀌어야 한다면 색상을 업데이트!
    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
    }
  }

  // 상단 탭을 눌렀을 때 스르륵 이동하는 함수
  void _scrollToSection(int index) async {
    setState(() {
      _selectedIndex = index;
      _isTappingTab = true; // 이동하는 동안 자동 감지 끄기
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
    
    // 이동 완료 후 자동 감지 다시 켜기
    await Future.delayed(const Duration(milliseconds: 50));
    _isTappingTab = false; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), 
      body: SafeArea(
        child: Column(
          children: [
            // =========================================================
            // [상단바 영역] 
            // =========================================================
            Container(
              color: const Color(0xFFF9F9F9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // 👇👇👇 요청 4. 한가운데 Settings 제목 추가 👇👇👇
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Text(
                          "Settings",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 고정된 상단 탭 (가로 스크롤)
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
                            // 👇👇👇 요청 3. 밑줄 데코레이션(border) 삭제 완료 👇👇👇
                            child: Text(
                              _tabTitles[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                color: isActive ? const Color(0xFFD32F2F) : Colors.grey.shade400,
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

            // =========================================================
            // [본문 영역] 스크롤 되는 설정 내용들
            // =========================================================
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController, // 💡 여기에 센서를 달아줍니다!
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

  // 박스와 구분선을 그려주는 함수
  Widget _buildSectionBox(int index) {
    bool isLastItem = index == _tabTitles.length - 1; // 마지막 항목인지 확인

    return Column(
      key: _sectionKeys[index], 
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목 (빨간색)
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
          child: Text(
            _tabTitles[index],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD32F2F), 
            ),
          ),
        ),
        
        // 빨간 테두리 둥근 박스
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD32F2F), width: 1.2), 
          ),
          child: Text(
            "${_tabTitles[index]} 설정 내용을 여기에 넣으세요!",
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),

        // 👇👇👇 요청 1. 양쪽 끝 여백이 있는 적당한 길이의 구분선 추가 👇👇👇
        if (!isLastItem) // 마지막 옵션 밑에는 선을 긋지 않습니다.
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0), // 위아래 간격 넉넉히!
            child: Divider(
              color: Color(0xFFE0E0E0),
              thickness: 1.0,
              indent: 30.0,    // 💡 왼쪽 여백을 주어 길이가 꽉 차지 않게 만듦
              endIndent: 30.0, // 💡 오른쪽 여백을 주어 길이가 꽉 차지 않게 만듦
            ),
          ),
      ],
    );
  }
}
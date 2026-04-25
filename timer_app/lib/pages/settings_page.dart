import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:timer_app/pages/shared_design.dart';
import 'package:flutter/gestures.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_settings_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeItem {
  final String name;
  final Color? color;
  final String? video;
  final bool isLocked;

  const ThemeItem({
    required this.name,
    this.color,
    this.video,
    this.isLocked = false,
  });
}

class AppThemePreset {
  final Color bg;
  final Color clock;
  final Color digital;
  final Color indicator;
  final String bgVideo;

  const AppThemePreset({
    required this.bg,
    required this.clock,
    required this.digital,
    required this.indicator,
    this.bgVideo = "사용 안 함",
  });
}

class AuthService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ✅ Google 로그인
  static Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      print("구글 로그인 에러: $e");
      return null;
    }
  }

  // ✅ 이메일 로그인 (차단 X)
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("이메일 로그인 에러: $e");
      return null;
    }
  }

  static Future<User?> signUpWithEmail(String email, String password) async {
    print("🔥 Firebase apps: ${Firebase.apps}");

    print("🔥 [SIGNUP START]");
    print("📧 email: $email");
    print("🔑 pw: $password");
    print("👤 currentUser: ${_auth.currentUser}");

    try {
      if (_auth.currentUser != null) {
        print("⚠️ 기존 유저 있어서 로그아웃 시도");
        await _auth.signOut();
      }

      print("🚀 createUserWithEmailAndPassword 호출 직전");

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("✅ Firebase 응답 받음");

      final user = result.user;

      print("👤 생성된 user: $user");

      if (user != null && !user.emailVerified) {
        print("📨 인증 메일 전송");
        await user.sendEmailVerification();
      }

      print("🔥 [SIGNUP END SUCCESS]");
      return user;
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException");
      print("코드: ${e.code}");
      print("메시지: ${e.message}");
      return null;
    } catch (e, stack) {
      print("💥 일반 에러");
      print("에러: $e");
      print("스택: $stack");
      return null;
    }
  }

  // ✅ 로그아웃
  static Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // ✅ 탈퇴
  static Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await user.delete();
    } catch (e) {
      print("탈퇴 에러: $e");
    }
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> _tabTitles = [
    "계정 설정",
    "즐겨 찾기",
    "테마",
    "시계 설정",
    "알림 설정",
    "BGM",
    "고객 센터",
  ];
  RewardedAd? _rewardedAd;
  bool _isAdReady = false;
  bool _isLoadingAd = false;
  User? _user;

  Widget _buildAdRewardBox(Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Column(
        children: [
          Text(
            "광고 보고 포인트 받기",
            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isAdReady ? _showRewardAd : null,
            child: Text(
              _isAdReady ? "+15 포인트" : (_isLoadingAd ? "광고 로딩중..." : "광고 준비중"),
            ),
          ),
        ],
      ),
    );
  }

  final List<AppThemePreset> _themePresets = [
    const AppThemePreset(
      bg: Color(0xFF252528),
      clock: Color.fromARGB(255, 185, 70, 70),
      digital: Color(0xFFE5E5EA),
      indicator: Color(0xFF8E8E93),
    ),
    const AppThemePreset(
      bg: Color(0xFF252528),
      clock: Color(0xFF4A4A4D),
      digital: Color(0xFFE5E5EA),
      indicator: Color(0xFF8E8E93),
    ),
    const AppThemePreset(
      bg: Color(0xFFF9F9F9),
      clock: Color(0xFFD32F2F),
      digital: Color(0xFF1C1C1E),
      indicator: Color(0xFFD32F2F),
    ),
    const AppThemePreset(
      bg: Color(0xFF1C2536),
      clock: Color(0xFF2D3C5A),
      digital: Color(0xFFFFFFFF),
      indicator: Color(0xFF8B9BB4),
    ),
    const AppThemePreset(
      bg: Color(0xFF1E2E26),
      clock: Color(0xFF334A3E),
      digital: Color(0xFFE2E8E4),
      indicator: Color(0xFF88A094),
    ),
    const AppThemePreset(
      bg: Color(0xFFF4EFE6),
      clock: Color(0xFFD1C2A5),
      digital: Color(0xFF5C4E3A),
      indicator: Color(0xFF9E8E76),
    ),

    const AppThemePreset(
      bg: Color(0xFFE8F5E9),
      clock: Color(0xFF81C784),
      digital: Color(0xFF2E7D32),
      indicator: Color(0xFF388E3C),
    ),
    const AppThemePreset(
      bg: Color(0xFF2A2344),
      clock: Color(0xFF524582),
      digital: Color(0xFFE6E2F1),
      indicator: Color(0xFFA197C4),
    ),
    const AppThemePreset(
      bg: Color(0xFFFFF0E5),
      clock: Color(0xFFFF8A65),
      digital: Color(0xFF5D4037),
      indicator: Color(0xFF8D6E63),
    ),
    const AppThemePreset(
      bg: Color(0xFF0F172A),
      clock: Color(0xFF38BDF8),
      digital: Color(0xFFF8FAFC),
      indicator: Color(0xFF94A3B8),
    ),

    // 비 오는 밤 프리셋
    const AppThemePreset(
      bg: Color.fromARGB(255, 111, 184, 212),
      clock: Colors.transparent,
      digital: Color(0xFF9E9E9E),
      indicator: Colors.white70,
      bgVideo: "비 오는 밤 (Rain)",
    ),

    // 🌸 [추가됨] 벚꽃 프리셋 (시계판은 투명하게 설정)
    const AppThemePreset(
      bg: Color(0xFFFFB7C5),
      clock: Colors.transparent,
      digital: Color(0xFFFFB7C5), // 벚꽃빛깔 핑크 숫자
      indicator: Colors.white70,
      bgVideo: "벚꽃 (Cherry Blossom)",
    ),
  ];

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

    const ThemeItem(name: "비 오는 밤", color: Colors.grey, video: "비 오는 밤 (Rain)"),
    // 🌸 [추가됨] 벚꽃 영상 옵션
    const ThemeItem(
      name: "벚꽃",
      color: Color(0xFFFFB7C5),
      video: "벚꽃 (Cherry Blossom)",
    ),
  ];

  late List<GlobalKey> _sectionKeys;
  late List<GlobalKey> _tabKeys;
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isTappingTab = false;

  void _stopPreview() {}

  List<Map<String, dynamic>> _favorites = [];
  void _loadRewardedAd() {
    if (_isLoadingAd) return;

    _isLoadingAd = true;

    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // 테스트 광고
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdReady = true;
          _isLoadingAd = false;
        },
        onAdFailedToLoad: (error) {
          print("🔥 광고 로드 실패: $error"); // 🔥 이거 추가
          _isAdReady = false;
          _isLoadingAd = false;
        },
      ),
    );
  }

  Future<void> _addPoint(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await ref.set({
      'point': FieldValue.increment(amount),
    }, SetOptions(merge: true));
  }

  Future<void> _rewardPoint(int amount) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // 🔥 로그인 유저 → Firebase 저장
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await ref.set({
        'point': FieldValue.increment(amount),
      }, SetOptions(merge: true));
    } else {
      // 🔥 게스트 → 로컬 저장
      final prefs = await SharedPreferences.getInstance();
      int current = prefs.getInt('point') ?? 0;

      await prefs.setInt('point', current + amount);
    }
  }

  void _showRewardAd() {
    if (!_isAdReady || _rewardedAd == null) {
      print("광고 준비 안됨");
      _loadRewardedAd();
      return;
    }

    final ad = _rewardedAd!;

    // 🔥 광고 lifecycle 처리 (핵심)
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd(); // 광고 닫힌 후 다시 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
      },
    );

    // 🔥 광고 실행
    ad.show(
      onUserEarnedReward: (ad, reward) async {
        await _rewardPoint(15);
      },
    );

    // 🔥 참조만 끊기
    _rewardedAd = null;
    _isAdReady = false;
  }

  @override
  void initState() {
    super.initState();

    _loadRewardedAd();
    _sectionKeys = List.generate(_tabTitles.length, (index) => GlobalKey());
    _tabKeys = List.generate(_tabTitles.length, (index) => GlobalKey());
    _scrollController.addListener(_onScroll);
    _user = FirebaseAuth.instance.currentUser;
    _refreshUser(); // 🔥 이거 추가
    _loadFavorites();
  }

  void _refreshUser() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();

    setState(() {
      _user = FirebaseAuth.instance.currentUser;
    });

    print("🔄 인증 상태 갱신: ${_user?.emailVerified}");
  }

  @override
  void dispose() {
    _scrollController.dispose();

    _rewardedAd?.dispose(); // 🔥 이거 추가

    // 🔥 추가 (미리듣기 소리 정지)
    GlobalBgmManager.stopAllSound();

    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favsJson = prefs.getString('my_favorites');
    if (favsJson != null) {
      setState(() {
        _favorites = List<Map<String, dynamic>>.from(jsonDecode(favsJson));
      });
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_favorites', jsonEncode(_favorites));
  }

  void _addFavorite(String name) {
    final newFav = {
      "name": name,
      "bgColor": globalBgColor.value.value,
      "clockColor": globalClockColor.value.value,
      "digitalColor": globalDigitalColor.value.value,
      "indicatorColor": globalIndicatorColor.value.value,
      "bgVideoName": globalBgVideoName.value,
      "isTimerMode": globalIsTimerMode.value,
      "timerMaxString": globalTimerMaxString.value,
      "displayMode": globalDisplayMode.value,
      "indicatorMode": globalIndicatorMode.value,
      "digitalStyle": globalDigitalStyle.value,
      "digitalFontSize": globalDigitalFontSize.value,
      "hapticIntensity": globalHapticIntensity.value,
      "alarmEnabled": globalAlarmEnabled.value,
      "alarmSound": globalAlarmSound.value,
      "bgmEnabled": globalBgmEnabled.value,
      "bgmTrack": globalBgmTrack.value,
    };

    setState(() {
      _favorites.add(newFav);
    });
    _saveFavorites();
  }

  void _applyFavorite(Map<String, dynamic> fav) {
    setState(() {
      globalBgColor.value = Color(fav["bgColor"]);
      globalClockColor.value = Color(fav["clockColor"]);
      globalDigitalColor.value = Color(fav["digitalColor"]);
      globalIndicatorColor.value = Color(fav["indicatorColor"]);
      globalBgVideoName.value = fav["bgVideoName"] ?? "사용 안 함";
      globalIsTimerMode.value = fav["isTimerMode"] ?? true;
      globalTimerMaxString.value = fav["timerMaxString"] ?? "60초 (1분)";
      globalDisplayMode.value = fav["displayMode"] ?? "BOTH";
      globalIndicatorMode.value = fav["indicatorMode"] ?? "NUMBER";
      globalDigitalStyle.value = fav["digitalStyle"] ?? "DEFAULT";
      globalDigitalFontSize.value = fav["digitalFontSize"] ?? "MEDIUM";
      globalHapticIntensity.value = fav["hapticIntensity"] ?? "NONE";
      globalAlarmEnabled.value = fav["alarmEnabled"] ?? true;
      globalAlarmSound.value = fav["alarmSound"] ?? "기본 알람";
      globalBgmEnabled.value = fav["bgmEnabled"] ?? false;
      globalBgmTrack.value = fav["bgmTrack"] ?? "기본 BGM";
    });
    // 파이어베이스 저장 (있다면)
    FirebaseSettingsService.saveSettingsDebounced();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${fav["name"]}" 테마가 적용되었습니다!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAddFavoriteDialog(Color accentColor) {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            "즐겨찾기 추가",
            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "예: 집중 모드, 벚꽃 테마 등"),
            maxLength: 15,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                _addFavorite(nameController.text.trim());
                Navigator.pop(context);
              },
              child: Text(
                "저장",
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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
    setState(() {
      _selectedIndex = index;
      _isTappingTab = true;
    });
    _scrollToTabCenter(index);
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

  void _scrollToTabCenter(int index) {
    final context = _tabKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _showCustomPicker(
    String title,
    ValueNotifier<Color> colorNotifier,
    Color accentColor,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final double popupWidth = screenWidth * 0.85;
        final double popupHeight = screenHeight * 0.5;

        final int columns = 6;
        final double spacing = 12.0;
        final double borderRadius = 12.0;

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: popupWidth,
            height: popupHeight,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "$title 선택",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _backgroundOptions.length,
                    itemBuilder: (context, index) {
                      final item = _backgroundOptions[index];

                      bool isSelected = false;
                      if (title == "배경색") {
                        if (item.video != null) {
                          isSelected = globalBgVideoName.value == item.video;
                        } else {
                          isSelected =
                              colorNotifier.value == item.color &&
                              globalBgVideoName.value == "사용 안 함";
                        }
                      } else {
                        isSelected = colorNotifier.value == item.color;
                      }

                      if (title != "배경색" && item.video != null)
                        return const SizedBox.shrink();
                      if (item.color == Colors.transparent && title != "시계색")
                        return const SizedBox.shrink();

                      return GestureDetector(
                        onTap: () {
                          if (item.isLocked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('잠겨있는 테마입니다. (포인트 기능 준비 중)'),
                              ),
                            );
                            return;
                          }

                          if (item.color != null)
                            colorNotifier.value = item.color!;

                          if (title == "배경색") {
                            if (item.video != null) {
                              globalBgVideoName.value = item.video!;
                            } else {
                              globalBgVideoName.value = "사용 안 함";
                            }
                          }

                          Navigator.pop(context);
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: item.color,
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? accentColor
                                      : (item.color == Colors.transparent
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade300),
                                  width: isSelected ? 3.0 : 1.0,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: item.color == Colors.transparent
                                  ? const Center(
                                      child: Icon(
                                        Icons.format_color_reset,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    )
                                  : null,
                            ),
                            if (item.video != null)
                              const Icon(
                                Icons.wallpaper,
                                color: Colors.white,
                                size: 20,
                              ),

                            if (item.isLocked)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(
                                    borderRadius,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.lock,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "닫기",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // 🌟 [새로 추가할 함수 2개] 알림음/BGM 전용 팝업 및 버튼 UI
  // =========================================================
  void _showAudioPickerDialog(
    String title,
    List<String> options,
    ValueNotifier<String> notifier,
    Color accentColor,
    Function(String) onPreview,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final double popupWidth = screenWidth * 0.85;
        final double popupHeight = screenHeight * 0.6; // 리스트가 기니까 세로로 길게

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: popupWidth,
            height: popupHeight,
            padding: const EdgeInsets.only(
              top: 20.0,
              left: 16.0,
              right: 16.0,
              bottom: 12.0,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: notifier,
                    builder: (context, currentValue, _) {
                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: options.length,
                        separatorBuilder: (context, index) =>
                            Divider(color: Colors.grey.shade200, height: 1),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          final isSelected = option == currentValue;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 4.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            // 선택된 항목은 예쁜 반투명 배경색 적용
                            tileColor: isSelected
                                ? accentColor.withOpacity(0.1)
                                : Colors.transparent,
                            leading: Icon(
                              title.contains("BGM")
                                  ? Icons.music_note
                                  : Icons.notifications_active,
                              color: isSelected
                                  ? accentColor
                                  : Colors.grey.shade400,
                            ),
                            title: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? accentColor
                                    : Colors.black87,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: accentColor)
                                : null,
                            onTap: () {
                              notifier.value = option; // 값 변경
                              onPreview(option); // 미리듣기 재생
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "닫기",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget audioPickerRow(
    String title,
    List<String> options,
    ValueNotifier<String> notifier,
    Color accentColor,
    Function(String) onPreview,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () => _showAudioPickerDialog(
              "$title 선택",
              options,
              notifier,
              accentColor,
              onPreview,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: notifier,
                    builder: (context, val, _) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.35,
                        ),
                        child: Text(
                          val,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget colorPicker(
    String title,
    ValueNotifier<Color> notifier,
    Color accentColor,
  ) {
    return ValueListenableBuilder<Color>(
      valueListenable: notifier,
      builder: (context, color, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => _showCustomPicker(title, notifier, accentColor),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color == Colors.transparent
                          ? Colors.grey.shade400
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: color == Colors.transparent
                      ? const Icon(
                          Icons.format_color_reset,
                          color: Colors.grey,
                          size: 20,
                        )
                      : (title == "배경색" && globalBgVideoName.value != "사용 안 함")
                      ? const Icon(
                          Icons.wallpaper,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildTwoOptionToggle(
    String title,
    String opt1,
    String opt2,
    ValueNotifier<bool> notifier,
    Color accentColor,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, isTrue, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 100,
                      maxWidth: 150,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<bool>(
                        groupValue: isTrue,
                        thumbColor: Colors.white,
                        backgroundColor: Colors.grey.shade200,
                        children: {
                          true: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              opt1,
                              style: TextStyle(
                                color: isTrue ? accentColor : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          false: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              opt2,
                              style: TextStyle(
                                color: !isTrue ? accentColor : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        },
                        onValueChanged: (val) {
                          if (val != null) notifier.value = val;
                        },
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
        builder: (context, rawAccentColor, child) {
          Color uiAccentColor = rawAccentColor == Colors.transparent
              ? Colors.grey.shade800
              : rawAccentColor;

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
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.arrow_back_ios_new,
                                    color: uiAccentColor,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              Text(
                                "SETTINGS",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: uiAccentColor,
                                ),
                              ),
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
                                  key: _tabKeys[index],
                                  margin: const EdgeInsets.only(right: 20.0),
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    _tabTitles[index],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: isActive
                                          ? uiAccentColor
                                          : Colors.grey.shade400,
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
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        children: [
                          ...List.generate(_tabTitles.length, (index) {
                            return _buildSectionBox(index, uiAccentColor);
                          }),

                          // 🔥🔥🔥 여기 추가
                          _buildAdRewardBox(uiAccentColor),
                        ],
                      ),
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

  Widget _loginButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final size = MediaQuery.of(context).size;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: size.height * 0.015,
          horizontal: size.width * 0.03,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: size.width * 0.06),
            SizedBox(width: size.width * 0.03),

            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: size.width * 0.04,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String text, Color color, VoidCallback onTap) {
    final size = MediaQuery.of(context).size;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(vertical: size.height * 0.012),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: size.width * 0.035,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<Map<String, String>?> _showEmailDialog() {
    final email = TextEditingController();
    final pw = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("이메일 로그인"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: "이메일"),
              ),
              TextField(
                controller: pw,
                obscureText: true,
                decoration: const InputDecoration(labelText: "비밀번호"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  "email": email.text.trim(),
                  "pw": pw.text.trim(),
                  "type": "login", // ✔ 로그인
                });
              },
              child: const Text("로그인"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  "email": email.text.trim(),
                  "pw": pw.text.trim(),
                  "type": "signup", // ✔ 회원가입
                });
              },
              child: const Text("회원가입"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountSection(Color accentColor) {
    final size = MediaQuery.of(context).size;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Column(
          children: [
            if (user == null) ...[
              _loginButton(
                "Google로 로그인",
                Icons.g_mobiledata,
                accentColor,
                () async {
                  final result = await AuthService.signInWithGoogle();
                  if (result != null) {
                    await FirebaseSettingsService.loadSettingsFromCloud();
                  }
                },
              ),

              SizedBox(height: size.height * 0.01),
              _loginButton("이메일 로그인", Icons.email, accentColor, () async {
                print("🔥 이메일 버튼 클릭");

                final result = await _showEmailDialog();

                print("📦 dialog result: $result");

                if (result == null) return;

                final email = result["email"]!;
                final pw = result["pw"]!;
                final type = result["type"];

                print("📧 입력 email: $email");
                print("🔑 입력 pw: $pw");
                print("🧭 type: $type");

                // 🔥 입력값 체크 필수
                if (type == "login" && (email.isEmpty || pw.isEmpty)) {
                  print("❌ 로그인 입력값 없음");
                  return;
                }

                if (type == "signup") {
                  // 🔥 회원가입은 페이지로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SignUpPage()),
                  );
                } else {
                  final user = await AuthService.signInWithEmail(email, pw);
                  print("🎯 로그인 결과: $user");
                }
              }),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.person, color: accentColor),
                  SizedBox(width: size.width * 0.03),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email ?? "사용자",
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),

                        if (!user.emailVerified) ...[
                          Text(
                            "이메일 인증 필요",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: size.width * 0.03,
                            ),
                          ),

                          const SizedBox(height: 6),

                          TextButton(
                            onPressed: () async {
                              final user = FirebaseAuth.instance.currentUser;

                              await user?.reload(); // 🔥 핵심

                              final refreshedUser =
                                  FirebaseAuth.instance.currentUser;

                              setState(() {
                                _user = refreshedUser;
                              });

                              print(
                                "🔄 인증 상태: ${refreshedUser?.emailVerified}",
                              );

                              if (refreshedUser?.emailVerified == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("인증 완료!")),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("아직 인증 안됨")),
                                );
                              }
                            },
                            child: const Text("인증 확인"),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.015),

              Row(
                children: [
                  Expanded(
                    child: _actionButton("로그아웃", accentColor, () async {
                      await FirebaseSettingsService.saveSettingsToCloud();
                      await AuthService.signOut();
                    }),
                  ),
                  SizedBox(width: size.width * 0.02),
                  Expanded(
                    child: _actionButton("탈퇴", Colors.red, () async {
                      await AuthService.deleteAccount();
                    }),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionBox(int index, Color accentColor) {
    bool isLastItem = index == _tabTitles.length - 1;
    Widget sectionContent;
    if (index == 0) {
      sectionContent = _buildAccountSection(accentColor);
    } else if (index == 1) {
      // 🌟 [수정] 즐겨찾기 탭 화면 구성
      sectionContent = Column(
        children: [
          if (_favorites.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                "저장된 즐겨찾기가 없습니다.\n아래 + 버튼을 눌러 현재 설정을 저장해보세요!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, height: 1.5),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _favorites.length,
              itemBuilder: (context, i) {
                final fav = _favorites[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.star, color: accentColor),
                  title: Text(
                    fav["name"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: () {
                      // 👇 버튼을 누르면 바로 안 지우고 팝업(Dialog)을 띄웁니다.
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            title: Text(
                              "즐겨찾기 삭제",
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            content: const Text(
                              "해당 즐겨찾기를 제거하시겠습니까?",
                              style: TextStyle(fontSize: 15),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context), // 팝업 닫기 (취소)
                                child: const Text(
                                  "취소",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // 진짜 삭제 실행
                                  setState(() {
                                    _favorites.removeAt(i);
                                  });
                                  _saveFavorites();
                                  Navigator.pop(context); // 팝업 닫기
                                },
                                child: const Text(
                                  "제거",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  onTap: () => _applyFavorite(fav),
                );
              },
            ),
          const SizedBox(height: 12),
          // 하단 + 버튼
          GestureDetector(
            onTap: () => _showAddFavoriteDialog(accentColor),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: 32, color: accentColor),
            ),
          ),
        ],
      );
    } else if (index == 2) {
      sectionContent = AnimatedBuilder(
        animation: Listenable.merge([
          globalBgColor,
          globalClockColor,
          globalDigitalColor,
          globalIndicatorColor,
          globalBgVideoName,
        ]),
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "프리셋 선택",
                style: TextStyle(
                  fontSize: 14,
                  color: accentColor.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: _themePresets.map((theme) {
                  bool isSelected =
                      globalBgColor.value == theme.bg &&
                      globalClockColor.value == theme.clock &&
                      globalDigitalColor.value == theme.digital &&
                      globalIndicatorColor.value == theme.indicator &&
                      globalBgVideoName.value == theme.bgVideo;
                  bool isVideoPreset = theme.bgVideo != "사용 안 함";

                  return GestureDetector(
                    onTap: () {
                      globalBgColor.value = theme.bg;
                      globalClockColor.value = theme.clock;
                      globalDigitalColor.value = theme.digital;
                      globalIndicatorColor.value = theme.indicator;
                      globalBgVideoName.value = theme.bgVideo;
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? accentColor
                              : Colors.grey.shade300,
                          width: isSelected ? 3.0 : 1.0,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.5, 0.5],
                          colors: [theme.bg, theme.clock],
                        ),
                      ),
                      child: isVideoPreset
                          ? const Icon(
                              Icons.wallpaper,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),
              Text(
                "세부 색상 커스텀",
                style: TextStyle(
                  fontSize: 14,
                  color: accentColor.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          buildTwoOptionToggle(
            "모드 선택",
            "TMR",
            "SW",
            globalIsTimerMode,
            accentColor,
          ),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(
            title: "타이머 최대 눈금",
            options: const [
              "30초",
              "60초 (1분)",
              "120초 (2분)",
              "30분",
              "60분",
              "120분",
            ],
            notifier: globalTimerMaxString,
            accentColor: accentColor,
          ),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(
            title: "시계 표시",
            options: const ["BOTH", "ANALOG", "DIGITAL"],
            notifier: globalDisplayMode,
            accentColor: accentColor,
          ),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(
            title: "숫자 표시",
            options: const ["NUMBER", "DOT", "NONE"],
            notifier: globalIndicatorMode,
            accentColor: accentColor,
          ),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(
            title: "디지털 스타일",
            options: const ["DEFAULT", "SEGMENT", "FLIP"],
            notifier: globalDigitalStyle,
            accentColor: accentColor,
          ),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(
            title: "폰트 크기",
            options: const ["SMALL", "MEDIUM", "LARGE"],
            notifier: globalDigitalFontSize,
            accentColor: accentColor,
          ),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          CustomWheelPicker(
            title: "햅틱 진동",
            options: const ["NONE", "SOFT", "MEDIUM", "STRONG"],
            notifier: globalHapticIntensity,
            accentColor: accentColor,
          ),
        ],
      );
    } else if (index == 4) {
      sectionContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTwoOptionToggle(
            "타이머 종료 알림",
            "ON",
            "OFF",
            globalAlarmEnabled,
            accentColor,
          ),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          // 💡 CustomWheelPicker를 지우고 기존 로직을 그대로 살린 audioPickerRow!
          audioPickerRow(
            "알림 방식",
            alarmOptions,
            globalAlarmSound,
            accentColor,
            (val) => GlobalBgmManager.previewAlarmSound(val),
          ),
        ],
      );
    } else if (index == 5) {
      sectionContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTwoOptionToggle(
            "배경 음악 재생",
            "ON",
            "OFF",
            globalBgmEnabled,
            accentColor,
          ),
          Divider(color: Colors.grey.shade200, height: 16, thickness: 1),
          // 💡 CustomWheelPicker를 지우고 기존 로직을 그대로 살린 audioPickerRow!
          audioPickerRow(
            "트랙 선택",
            bgmOptions,
            globalBgmTrack,
            accentColor,
            (val) => GlobalBgmManager.previewBgm(val),
          ),
        ],
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
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
            child: Divider(
              color: Color(0xFFE0E0E0),
              thickness: 1.0,
              indent: 30.0,
              endIndent: 30.0,
            ),
          ),
      ],
    );
  }
}

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final email = TextEditingController();
  final pw = TextEditingController();
  final pwConfirm = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "이메일"),
            ),
            TextField(
              controller: pw,
              obscureText: true,
              decoration: const InputDecoration(labelText: "비밀번호"),
            ),
            TextField(
              controller: pwConfirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: "비밀번호 확인"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                if (pw.text != pwConfirm.text) {
                  print("비밀번호 다름");
                  return;
                }

                final user = await AuthService.signUpWithEmail(
                  email.text.trim(),
                  pw.text.trim(),
                );

                if (user != null) {
                  // 🔥 1. 성공 팝업
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("회원가입 완료"),
                      content: const Text("회원가입에 성공했습니다"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // 팝업 닫기
                            Navigator.pop(context); // 회원가입 페이지 닫기
                          },
                          child: const Text("확인"),
                        ),
                      ],
                    ),
                  );
                } else {
                  // 🔥 실패 처리
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("회원가입 실패")));
                }
              },
              child: const Text("회원가입"),
            ),
          ],
        ),
      ),
    );
  }
}

class EmailLoginPage extends StatefulWidget {
  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final email = TextEditingController();
  final pw = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("로그인")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "이메일"),
            ),
            TextField(
              controller: pw,
              obscureText: true,
              decoration: const InputDecoration(labelText: "비밀번호"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final user = await AuthService.signInWithEmail(
                  email.text.trim(),
                  pw.text.trim(),
                );

                print("로그인 결과: $user");
              },
              child: const Text("로그인"),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignUpPage()),
                );
              },
              child: const Text("회원가입"),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomWheelPicker extends StatefulWidget {
  final String title;
  final List<String> options;
  final ValueNotifier<String> notifier;
  final Color accentColor;
  final Function(String)? onSelected;
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
  void didUpdateWidget(covariant CustomWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    int targetIndex = widget.options.indexOf(widget.notifier.value);
    if (targetIndex != -1 &&
        _controller.hasClients &&
        _controller.selectedItem != targetIndex) {
      _controller.jumpToItem(targetIndex);
    }
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
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 16,
              color: widget.accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                      Container(
                        width: double.infinity,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                            if (widget.onSelected != null) {
                              widget.onSelected!(widget.options[index]);
                            }
                          },
                          children: List<Widget>.generate(
                            widget.options.length,
                            (index) {
                              return Center(
                                child: ValueListenableBuilder<String>(
                                  valueListenable: widget.notifier,
                                  builder: (context, currentValue, child) {
                                    bool isSelected =
                                        widget.options[index] == currentValue;
                                    return Text(
                                      widget.options[index],
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: isSelected ? 15 : 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? widget.accentColor
                                            : widget.accentColor.withOpacity(
                                                0.4,
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
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

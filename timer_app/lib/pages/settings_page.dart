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
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart'; // ✅ kIsWeb 사용을 위해 꼭 필요
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'timer_page.dart';
import '../main.dart'; // 🔥 globalTimerPageKey를 가져오기 위해 필요합니다.
import 'dart:convert';
import '../services/point_service.dart';
import '../pages/point_shop_page.dart';
import 'package:vibration/vibration.dart';

// ✅ 고객센터 페이지 이동을 위한 임포트 (만약 파일명이 다르다면 수정해주세요)
import 'notice_page.dart';
import 'faq_page.dart';

class ThemeItem {
  final String name;
  final Color? color;
  final String? video;
  final bool isPremium;
  final String id;
  final int unlockPoint;

  const ThemeItem({
    required this.name,
    this.color,
    this.video,
    this.isPremium = false,
    this.id = "",
    this.unlockPoint = 0,
  });
}

class AppThemePreset {
  final Color bg;
  final Color clock;
  final Color digital;
  final Color indicator;
  final String bgVideo;
  final String clockVideo;

  final String id;
  final bool isPremium;
  final int unlockPoint;

  const AppThemePreset({
    required this.bg,
    required this.clock,
    required this.digital,
    required this.indicator,
    this.bgVideo = "사용 안 함",
    this.clockVideo = "사용 안 함",

    // 잠금 테마 전용 옵션
    this.id = "",
    this.isPremium = false,
    this.unlockPoint = 0,
  });
}

class AuthService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    try {
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
      return user;
    } catch (e) {
      print("회원가입 에러: $e");
      return null;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

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
    "뽀모도로",
    "알림 설정",
    "BGM",
    "고객 센터",
  ];
  RewardedAd? _rewardedAd;
  bool _isAdReady = false;
  bool _isLoadingAd = false;
  User? _user;

  final PointService _pointService = PointService();
  Set<String> _unlockedItemIds = {}; // ✅ 잠금 해제된 아이템 ID들 보관

  OverlayEntry? _previewOverlay;
  int _unlockedBgMediaSlots = 0; // 배경 사진 슬롯
  int _unlockedClockMediaSlots = 0; // 시계 사진 슬롯
  int _unlockedThemeSlots = 0;
  static const int _customThemeSlotPrice = 200;
  static const int _premiumAlarmPrice = 300;
  static const int _premiumBgmPrice = 300;
  static const int _specialThemePrice = 500;
  static const int _customPhotoSlotPrice = 400;
  static const int _specialBgPrice = 300;

  List<String> _localBgMediaPaths = []; // 배경 사진 저장 배열
  List<String> _localClockMediaPaths = []; // 시계 사진 저장 배열
  List<AppThemePreset> _localCustomPresets = [];
  Set<String> _unlockedSpecialThemes = {};
  Set<String> _unlockedAlarmSounds = {};
  Set<String> _unlockedBgmTracks = {};
  // ---------------- ✨ 여기서부터 통째로 교체 ✨ ----------------
  Future<void> _loadCustomData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    List<AppThemePreset> loadedThemes = [];

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      final List<dynamic> decoded = data?['customThemes'] ?? [];

      _unlockedBgMediaSlots = data?['unlockedBgMediaSlots'] ?? 0;
      _unlockedClockMediaSlots = data?['unlockedClockMediaSlots'] ?? 0;
      _unlockedThemeSlots = data?['unlockedThemeSlots'] ?? 0;

      loadedThemes = decoded.map((theme) {
        return AppThemePreset(
          bg: Color(theme['bg']),
          clock: Color(theme['clock']),
          digital: Color(theme['digital']),
          indicator: Color(theme['indicator']),
          bgVideo: theme['bgVideo'] ?? "사용 안 함",
          clockVideo: theme['clockVideo'] ?? "사용 안 함",
        );
      }).toList();
    } else {
      final themeString = prefs.getString('local_custom_themes');

      _unlockedBgMediaSlots = prefs.getInt('unlockedBgMediaSlots') ?? 0;
      _unlockedClockMediaSlots = prefs.getInt('unlockedClockMediaSlots') ?? 0;
      _unlockedThemeSlots = prefs.getInt('unlockedThemeSlots') ?? 0;

      if (themeString != null) {
        final List<dynamic> decoded = jsonDecode(themeString);

        loadedThemes = decoded.map((data) {
          return AppThemePreset(
            bg: Color(data['bg']),
            clock: Color(data['clock']),
            digital: Color(data['digital']),
            indicator: Color(data['indicator']),
            bgVideo: data['bgVideo'] ?? "사용 안 함",
            clockVideo: data['clockVideo'] ?? "사용 안 함",
          );
        }).toList();
      }
    }

    setState(() {
      _localBgMediaPaths = prefs.getStringList('local_bg_media_paths') ?? [];

      _localClockMediaPaths =
          prefs.getStringList('local_clock_media_paths') ?? [];

      _localCustomPresets = loadedThemes;

      if (_localBgMediaPaths.length > _unlockedBgMediaSlots) {
        _unlockedBgMediaSlots = _localBgMediaPaths.length;
      }

      if (_localClockMediaPaths.length > _unlockedClockMediaSlots) {
        _unlockedClockMediaSlots = _localClockMediaPaths.length;
      }
      if (_unlockedThemeSlots < _localCustomPresets.length) {
        _unlockedThemeSlots = _localCustomPresets.length;
      }
    });
  }

  //   Future<void> _loadUnlockedThemes() async {
  //     final user = FirebaseAuth.instance.currentUser;

  //     if (user == null) {
  //       if (!mounted) return;

  //       setState(() {
  //         _unlockedSpecialThemes.clear();
  //       });

  // // 🔥 노을, 밤하늘, 내 갤러리 사진은 무료이므로 절대 강제로 지우지 않게 방어합니다!
  //           final isUsingPremiumBg =
  //               globalBgVideoName.value == "비 오는 밤 (Rain)" ||
  //               globalBgVideoName.value == "벚꽃 (Cherry Blossom)";

  //           final isUsingPremiumClock =
  //               globalClockVideoName.value == "비 오는 밤 (Rain)" ||
  //               globalClockVideoName.value == "벚꽃 (Cherry Blossom)";

  //           bool changed = false;

  //           if (isUsingPremiumBg) {
  //             globalBgVideoName.value = "사용 안 함";
  //             changed = true;
  //           }
  //           if (isUsingPremiumClock) {
  //             globalClockVideoName.value = "사용 안 함";
  //             changed = true;
  //           }

  //           if (changed) {
  //             saveSettings();
  //           }

  //       return;
  //     }

  Future<void> _loadUnlockedThemes() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _unlockedSpecialThemes.clear();
      });

      // 🔥 회원님 말씀대로 배경 영상/사진 자체는 무료이므로
      // 앱이 멋대로 "사용 안 함"으로 강제 초기화해버리던 로직을 완전히 삭제했습니다!

      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    final unlockedThemes = List<String>.from(
      data?['unlockedSpecialThemes'] ?? [],
    );

    if (!mounted) return;

    setState(() {
      _unlockedSpecialThemes = unlockedThemes.toSet();
    });
  }

  Future<void> _loadUnlockedAudioOptions() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _unlockedAlarmSounds.clear();
        _unlockedBgmTracks.clear();
      });

      final alarmIsLocked = _isAudioOptionLocked(
        "alarm",
        alarmOptions,
        globalAlarmSound.value,
      );

      final bgmIsLocked = _isAudioOptionLocked(
        "bgm",
        bgmOptions,
        globalBgmTrack.value,
      );

      if (alarmIsLocked && alarmOptions.isNotEmpty) {
        globalAlarmSound.value = alarmOptions.first;
      }

      if (bgmIsLocked && bgmOptions.isNotEmpty) {
        globalBgmTrack.value = bgmOptions.first;
      }

      saveSettings();
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    final unlockedAlarmSounds = List<String>.from(
      data?['unlockedAlarmSounds'] ?? [],
    );

    final unlockedBgmTracks = List<String>.from(
      data?['unlockedBgmTracks'] ?? [],
    );

    if (!mounted) return;

    setState(() {
      _unlockedAlarmSounds = unlockedAlarmSounds.toSet();
      _unlockedBgmTracks = unlockedBgmTracks.toSet();
    });

    final alarmIsLocked = _isAudioOptionLocked(
      "alarm",
      alarmOptions,
      globalAlarmSound.value,
    );

    final bgmIsLocked = _isAudioOptionLocked(
      "bgm",
      bgmOptions,
      globalBgmTrack.value,
    );

    if (alarmIsLocked && alarmOptions.isNotEmpty) {
      globalAlarmSound.value = alarmOptions.first;
    }

    if (bgmIsLocked && bgmOptions.isNotEmpty) {
      globalBgmTrack.value = bgmOptions.first;
    }

    saveSettings();
    FirebaseSettingsService.saveSettingsDebounced();
  }

  Future<void> _pickLocalImage(
    String type, {
    StateSetter? dialogSetState,
  }) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (type == "배경색") {
        _localBgMediaPaths.add(image.path);
        prefs.setStringList('local_bg_media_paths', _localBgMediaPaths);
      } else {
        _localClockMediaPaths.add(image.path);
        prefs.setStringList('local_clock_media_paths', _localClockMediaPaths);
      }
    });

    if (dialogSetState != null) dialogSetState(() {});
  }

  Future<void> _updateSlotCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unlockedBgMediaSlots', _unlockedBgMediaSlots);
    await prefs.setInt('unlockedClockMediaSlots', _unlockedClockMediaSlots);
    await prefs.setInt('unlockedThemeSlots', _unlockedThemeSlots);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'unlockedBgMediaSlots': _unlockedBgMediaSlots,
        'unlockedClockMediaSlots': _unlockedClockMediaSlots,
        'unlockedThemeSlots': _unlockedThemeSlots,
      }, SetOptions(merge: true));
    }
  }

  bool _isFreeAudioOption(List<String> options, String option) {
    if (options.isEmpty) return false;
    return option == options.first;
  }

  bool _isAudioOptionLocked(String type, List<String> options, String option) {
    if (_isFreeAudioOption(options, option)) {
      return false;
    }

    if (type == "alarm") {
      return !_unlockedAlarmSounds.contains(option);
    }

    if (type == "bgm") {
      return !_unlockedBgmTracks.contains(option);
    }

    return true;
  }

  Future<bool> _tryUnlockCustomThemeSlot() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      int nextSlots = _unlockedThemeSlots;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data() ?? {};

        final int currentPoint = data['point'] ?? 0;
        final int currentSlots =
            data['unlockedThemeSlots'] ?? _unlockedThemeSlots;

        if (currentPoint < _customThemeSlotPrice) {
          throw Exception('NOT_ENOUGH_POINT');
        }

        nextSlots = currentSlots + 1;

        transaction.set(ref, {
          'point': currentPoint - _customThemeSlotPrice,
          'unlockedThemeSlots': nextSlots,
        }, SetOptions(merge: true));
      });

      if (!mounted) return false;

      setState(() {
        _unlockedThemeSlots = nextSlots;
      });

      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("포인트가 부족합니다.")));

      return false;
    }
  }

  Future<bool> _tryUnlockMediaSlot(String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      int nextSlots = 1;
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data() ?? {};

        final int currentPoint = data['point'] ?? 0;
        final int currentSlots = type == "배경색"
            ? (data['unlockedBgMediaSlots'] ?? _unlockedBgMediaSlots)
            : (data['unlockedClockMediaSlots'] ?? _unlockedClockMediaSlots);

        if (currentPoint < _customPhotoSlotPrice) {
          throw Exception('NOT_ENOUGH_POINT');
        }

        nextSlots = currentSlots + 1;

        transaction.set(ref, {
          'point': currentPoint - _customPhotoSlotPrice,
          type == "배경색" ? 'unlockedBgMediaSlots' : 'unlockedClockMediaSlots': nextSlots,
        }, SetOptions(merge: true));
      });

      if (!mounted) return false;

      setState(() {
        if (type == "배경색") _unlockedBgMediaSlots = nextSlots;
        else _unlockedClockMediaSlots = nextSlots;
      });

      _updateSlotCount();

      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("포인트가 부족합니다.")));
      return false;
    }
  }

  void _showMediaSlotUnlockDialog(String type, Color accentColor, StateSetter dialogSetState) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 42),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$type 사진 슬롯을\n추가하시겠습니까?",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    height: 1.35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Icon(Icons.add_photo_alternate, color: accentColor, size: 34),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: Color(0xFFFFC928), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Text("P", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      ": $_customPhotoSlotPrice point",
                      style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text("아니요", style: TextStyle(color: Colors.black54, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                          final success = await _tryUnlockMediaSlot(type);
                          if (!success) return;
                          dialogSetState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$type 사진 슬롯이 추가되었습니다.")));
                        },
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(14)),
                          child: const Text("예", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _tryUnlockSpecialMedia(ThemeItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data() ?? {};
        final int currentPoint = data['point'] ?? 0;

        if (currentPoint < item.unlockPoint) throw Exception('NOT_ENOUGH_POINT');

        transaction.set(ref, {
          'point': currentPoint - item.unlockPoint,
        }, SetOptions(merge: true));
      });

      if (!mounted) return false;
      setState(() {
        _unlockedSpecialThemes.add(item.id);
      });
      await _saveUnlockedThemes();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("포인트가 부족합니다.")));
      return false;
    }
  }

  void _showSpecialMediaUnlockDialog(ThemeItem item, Color accentColor, StateSetter dialogSetState) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 42),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("구매하시겠습니까?", textAlign: TextAlign.center, style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: item.color ?? Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: const Icon(Icons.wallpaper, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 16),
                Text(item.name, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: Color(0xFFFFC928), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Text("P", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    Text(": ${item.unlockPoint} point", style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
                          child: const Text("아니요", style: TextStyle(color: Colors.black54, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                          final success = await _tryUnlockSpecialMedia(item);
                          if (!success) return;
                          dialogSetState(() {});
                        },
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(14)),
                          child: const Text("예", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _tryUnlockAudioOption({
    required String type,
    required String option,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    final int price = type == "alarm" ? _premiumAlarmPrice : _premiumBgmPrice;

    final String fieldName = type == "alarm"
        ? 'unlockedAlarmSounds'
        : 'unlockedBgmTracks';

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data() ?? {};

        final int currentPoint = data['point'] ?? 0;

        if (currentPoint < price) {
          throw Exception('NOT_ENOUGH_POINT');
        }

        transaction.set(ref, {
          'point': currentPoint - price,
          fieldName: FieldValue.arrayUnion([option]),
        }, SetOptions(merge: true));
      });

      if (!mounted) return false;

      setState(() {
        if (type == "alarm") {
          _unlockedAlarmSounds.add(option);
        } else {
          _unlockedBgmTracks.add(option);
        }
      });

      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("포인트가 부족합니다.")));

      return false;
    }
  }

  void _deleteImage(String type, int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (type == "배경색") {
        _localBgMediaPaths.removeAt(index);
        prefs.setStringList('local_bg_media_paths', _localBgMediaPaths);
      } else {
        _localClockMediaPaths.removeAt(index);
        prefs.setStringList('local_clock_media_paths', _localClockMediaPaths);
      }
    });
  }

  // ✅ 커스텀 테마 삭제 로직 (에러 3 해결: 복구됨)
  void _deleteTheme(int index) async {
    setState(() {
      _localCustomPresets.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    final encoded = _localCustomPresets
        .map(
          (t) => {
            'bg': t.bg.value,
            'clock': t.clock.value,
            'digital': t.digital.value,
            'indicator': t.indicator.value,
            'bgVideo': t.bgVideo,
            'clockVideo': t.clockVideo, // 🔥 추가
          },
        )
        .toList();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await _saveThemesToCloud();
    } else {
      await prefs.setString('local_custom_themes', jsonEncode(encoded));
    }
  }

  Future<void> _saveThemesToCloud() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final encoded = _localCustomPresets
        .map(
          (t) => {
            'bg': t.bg.value,
            'clock': t.clock.value,
            'digital': t.digital.value,
            'indicator': t.indicator.value,
            'bgVideo': t.bgVideo,
            'clockVideo': t.clockVideo,
          },
        )
        .toList();

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'customThemes': encoded,
    }, SetOptions(merge: true));
  }

  // ---------------- 여기까지가 함수 교체 끝 ----------------
  Future<void> _saveCurrentAsPresetLocal() async {
    final newPreset = AppThemePreset(
      bg: globalBgColor.value,
      clock: globalClockColor.value,
      digital: globalDigitalColor.value,
      indicator: globalIndicatorColor.value,
      bgVideo: globalBgVideoName.value,
      clockVideo: globalClockVideoName.value, // 🔥 추가
    );

    setState(() {
      _localCustomPresets.add(newPreset);
    });

    final prefs = await SharedPreferences.getInstance();
    final encoded = _localCustomPresets
        .map(
          (t) => {
            'bg': t.bg.value,
            'clock': t.clock.value,
            'digital': t.digital.value,
            'indicator': t.indicator.value,
            'bgVideo': t.bgVideo,
            'clockVideo': t.clockVideo, // 🔥 추가
          },
        )
        .toList();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await _saveThemesToCloud();
    } else {
      await prefs.setString('local_custom_themes', jsonEncode(encoded));
    }
  }

  // ✅ [수정] 삭제 확인 팝업 (아이템 삭제 vs 슬롯 삭제 구분)
  void _confirmDeletion(
    String title,
    VoidCallback onDelete, {
    bool isSlot = false,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(isSlot ? "$title 삭제" : "$title 삭제"),
        content: Text(
          isSlot
              ? "이 슬롯은 포인트로 구매했을 수 있습니다.\n삭제하면 슬롯이 영구적으로 사라지며, 소모된 포인트는 복구되지 않습니다.\n정말로 삭제하시겠습니까?"
              : "정말로 삭제하시겠습니까?\n삭제해도 슬롯(빈 칸)은 그대로 유지됩니다.",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            child: const Text("삭제"),
          ),
        ],
      ),
    );
  }

  void _showThemeUnlockDialog(AppThemePreset preset) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 42),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "구매하시겠습니까?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                // 스페셜 테마 카드에 보이는 아이콘과 동일한 형태
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.5, 0.5],
                      colors: [preset.bg, preset.clock],
                    ),
                  ),
                  child: const Icon(Icons.image, color: Colors.white, size: 28),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC928),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "P",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ": ${preset.unlockPoint} point",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            "아니요",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);

                          final success = await _tryUnlockTheme(preset);

                          if (!success) return;

                          setState(() {});
                        },
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            "예",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomThemeSlotUnlockDialog(Color accentColor) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 42),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "커스텀 테마 슬롯을\n추가하시겠습니까?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    height: 1.35,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Icon(Icons.add, color: accentColor, size: 34),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC928),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "P",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ": $_customThemeSlotPrice point",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            "아니요",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);

                          final success = await _tryUnlockCustomThemeSlot();

                          if (!success) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("커스텀 테마 슬롯이 추가되었습니다."),
                            ),
                          );
                        },
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            "예",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAudioUnlockDialog({
    required String type,
    required String option,
    required Color accentColor,
    required ValueNotifier<String> notifier,
    required Function(String) onPreview,
  }) {
    final int price = type == "alarm" ? _premiumAlarmPrice : _premiumBgmPrice;

    final IconData icon = type == "alarm"
        ? Icons.notifications_active
        : Icons.music_note;

    final String title = type == "alarm" ? "알림음을 구매하시겠습니까?" : "BGM을 구매하시겠습니까?";

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 42),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    height: 1.35,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Icon(icon, color: accentColor, size: 34),
                ),

                const SizedBox(height: 12),

                Text(
                  option,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC928),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "P",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ": $price point",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            "아니요",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);

                          final success = await _tryUnlockAudioOption(
                            type: type,
                            option: option,
                          );

                          if (!success) return;

                          notifier.value = option;
                          onPreview(option);
                        },
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            "예",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPreview(BuildContext context, String videoName) {
    if (_previewOverlay != null) return;

    _previewOverlay = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Material(
            color: Colors.black.withOpacity(0.6),
            child: SafeArea(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MediaPreviewWidget(videoName: videoName),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    Navigator.of(
      context,
      rootNavigator: true,
    ).overlay?.insert(_previewOverlay!);
  }

  void _hidePreview() {
    _previewOverlay?.remove();
    _previewOverlay = null;
  }

  // ✅ [복구] 광고 보상 박스
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
              _isAdReady ? "+100 포인트" : (_isLoadingAd ? "광고 로딩중..." : "광고 준비중"),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ [고객센터 용] 인앱 피드백 전송 함수
  void _showFeedbackDialog(Color accentColor) {
    final TextEditingController feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "피드백 및 버그 제보",
          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "내용을 입력하고 전송을 누르면 개발자에게 전달됩니다.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "여기에 내용을 입력하세요...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (feedbackController.text.trim().isEmpty) return;
              try {
                await FirebaseFirestore.instance.collection('feedbacks').add({
                  'content': feedbackController.text.trim(),
                  'userEmail': FirebaseAuth.instance.currentUser?.email ?? "익명",
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("소중한 의견 감사합니다!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("전송 실패. 네트워크를 확인하세요.")),
                );
              }
            },
            child: Text(
              "전송",
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  final List<AppThemePreset> _themePresets = [
    const AppThemePreset(
      id: "0xFF252528",
      isPremium: false,
      unlockPoint: 0,
      bg: Color(0xFF252528),
      clock: Color.fromARGB(255, 185, 70, 70),
      digital: Color(0xFFE5E5EA),
      indicator: Color(0xFF8E8E93),
    ),
    const AppThemePreset(
      id: "0xFF252528",
      isPremium: false,
      unlockPoint: 0,
      bg: Color(0xFF252528),
      clock: Color(0xFF4A4A4D),
      digital: Color(0xFFE5E5EA),
      indicator: Color(0xFF8E8E93),
    ),
    const AppThemePreset(
      id: "0xFFF9F9F9",
      isPremium: false,
      unlockPoint: 0,

      bg: Color(0xFFF9F9F9),
      clock: Color(0xFFD32F2F),
      digital: Color(0xFF1C1C1E),
      indicator: Color(0xFFD32F2F),
    ),
    const AppThemePreset(
      id: "0xFF1C2536",
      isPremium: false,
      unlockPoint: 0,

      bg: Color(0xFF1C2536),
      clock: Color(0xFF2D3C5A),
      digital: Color(0xFFFFFFFF),
      indicator: Color(0xFF8B9BB4),
    ),
    const AppThemePreset(
      id: "0xFF1E2E26",
      isPremium: false,
      unlockPoint: 0,
      bg: Color(0xFF1E2E26),
      clock: Color(0xFF334A3E),
      digital: Color(0xFFE2E8E4),
      indicator: Color(0xFF88A094),
    ),
    const AppThemePreset(
      id: "0xFFF4EFE6",
      isPremium: false,
      unlockPoint: 0,
      bg: Color(0xFFF4EFE6),
      clock: Color(0xFFD1C2A5),
      digital: Color(0xFF5C4E3A),
      indicator: Color(0xFF9E8E76),
    ),
    const AppThemePreset(
      id: "0xFFE8F5E9",
      isPremium: false,
      unlockPoint: 0,
      bg: Color(0xFFE8F5E9),
      clock: Color(0xFF81C784),
      digital: Color(0xFF2E7D32),
      indicator: Color(0xFF388E3C),
    ),
    const AppThemePreset(
      id: "0xFF2A2344",
      isPremium: false,
      unlockPoint: 0,
      bg: Color(0xFF2A2344),
      clock: Color(0xFF524582),
      digital: Color(0xFFE6E2F1),
      indicator: Color(0xFFA197C4),
    ),
    const AppThemePreset(
      id: "0xFFFFF0E5",
      isPremium: false,
      unlockPoint: 0,
      bg: Color(0xFFFFF0E5),
      clock: Color(0xFFFF8A65),
      digital: Color(0xFF5D4037),
      indicator: Color(0xFF8D6E63),
    ),
    const AppThemePreset(
      id: "0xFF0F172A",
      isPremium: false,
      unlockPoint: 0,
      bg: Color(0xFF0F172A),
      clock: Color(0xFF38BDF8),
      digital: Color(0xFFF8FAFC),
      indicator: Color(0xFF94A3B8),
    ),
    const AppThemePreset(
      id: "rain",
      isPremium: true,
      unlockPoint: 300,
      bg: Color.fromARGB(255, 111, 184, 212),
      clock: Colors.transparent,
      digital: Color(0xFF9E9E9E),
      indicator: Colors.white70,
      bgVideo: "비 오는 밤 (Rain)",
    ),
    const AppThemePreset(
      id: "cherry",
      isPremium: true,
      unlockPoint: 300,
      bg: Color(0xFFFFB7C5),
      clock: Colors.transparent,
      digital: Color(0xFFFFB7C5),
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
    const ThemeItem(
      name: "비 오는 밤",
      color: Color.fromARGB(255, 111, 184, 212),
      video: "비 오는 밤 (Rain)",
      isPremium: true,
      id: "rain",
      unlockPoint: 300,
    ),
    const ThemeItem(
      name: "벚꽃",
      color: Color(0xFFFFB7C5),
      video: "벚꽃 (Cherry Blossom)",
      isPremium: true,
      id: "cherry",
      unlockPoint: 300,
    ),
    const ThemeItem(
      name: "노을",
      color: Colors.orange,
      video: "노을 (Sunset)",
      isPremium: true,
      id: "sunset",
      unlockPoint: 300,
    ),
    const ThemeItem(
      name: "밤하늘",
      color: Colors.lightBlueAccent,
      video: "밤하늘 (Sky Moon)",
      isPremium: true,
      id: "skymoon",
      unlockPoint: 300,
    ),
  ];

  void _showPomodoroHelpDialog(Color accentColor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.timer, color: accentColor),
              const SizedBox(width: 8),
              Text(
                "뽀모도로 모드란?",
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "짧은 집중과 휴식을 반복하여 뇌의 집중력을 극대화하는 시간 관리 기법입니다. 🍅",
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  "⚙️ 동작 설정",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Text(
                  "• 집중 시간: 목표에만 몰두하는 시간\n"
                  "• 짧은 휴식: 집중 후 뇌를 잠깐 쉬게 해주는 시간\n"
                  "• 긴 휴식: 짧은 휴식 대신 길게 쉬면서 에너지를 완전히 회복하는 시간\n"
                  "• 긴 휴식 주기: 집중-휴식 사이클을 몇 번 반복한 후 '긴 휴식'을 가질지 결정하는 횟수\n"
                  "• 최대 뽀모도로 횟수: 타이머가 자동으로 종료될 총 뽀모도로 진행 횟수 한도",
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  "⚙️ 자동 시작 옵션",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Text(
                  "• 켜짐(ON): 이전 모드가 끝나면 화면 터치 없이 즉시 다음 타이머가 시작됩니다.\n"
                  "• 꺼짐(OFF): 화면을 터치해야 다음 타이머가 시작됩니다.",
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "확인",
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  late List<GlobalKey> _sectionKeys;
  late List<GlobalKey> _tabKeys;
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isTappingTab = false;

  void _stopPreview() {}
  void _previewHapticIntensity(String intensity) {
    final String value = intensity.toUpperCase();

    if (kIsWeb) return;
    if (value == "NONE") return;

    try {
      if (value == "SOFT") {
        Vibration.vibrate(duration: 20, amplitude: 80);
      } else if (value == "MEDIUM") {
        Vibration.vibrate(duration: 30, amplitude: 160);
      } else if (value == "STRONG") {
        Vibration.vibrate(duration: 40, amplitude: 255);
      }
    } catch (e) {
      debugPrint("햅틱 미리보기 실패: $e");
    }
  }

  List<Map<String, dynamic>> _favorites = [];

  void _loadRewardedAd() {
    if (kIsWeb) return; // ✅ [에러 해결] 웹 브라우저에서 광고 로드 명령 실행을 아예 막음
    if (_isLoadingAd) return;
    _isLoadingAd = true;
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdReady = true;
          _isLoadingAd = false;
        },
        onAdFailedToLoad: (error) {
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

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("로그인 후 광고 보상을 받을 수 있습니다.")));
      return;
    }

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    await ref.set({
      'point': FieldValue.increment(amount),
    }, SetOptions(merge: true));

    setState(() {});
  }

  void _showRewardAd() {
    if (kIsWeb) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("웹 버전에서는 광고가 지원되지 않습니다.")));
      return;
    }
    if (!_isAdReady || _rewardedAd == null) {
      _loadRewardedAd();
      return;
    }
    final ad = _rewardedAd!;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
      },
    );
    ad.show(
      onUserEarnedReward: (ad, reward) async {
        await _rewardPoint(100);
      },
    );
    _rewardedAd = null;
    _isAdReady = false;
  }

  Future<void> _saveUnlockedThemes() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'unlockedSpecialThemes': _unlockedSpecialThemes.toList(),
    }, SetOptions(merge: true));
  }

  Future<bool> _tryUnlockTheme(AppThemePreset preset) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    final doc = await ref.get();

    final data = doc.data() ?? {};

    int point = data['point'] ?? 0;

    if (point < preset.unlockPoint) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("포인트 부족")));

      return false;
    }

    await ref.set({
      'point': point - preset.unlockPoint,
    }, SetOptions(merge: true));

    _unlockedSpecialThemes.add(preset.id);

    await _saveUnlockedThemes();

    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
    _sectionKeys = List.generate(_tabTitles.length, (index) => GlobalKey());
    _tabKeys = List.generate(_tabTitles.length, (index) => GlobalKey());
    _scrollController.addListener(_onScroll);
    _user = FirebaseAuth.instance.currentUser;
    _refreshUser();
    _loadFavorites(); // 🔥 추가
    _loadCustomData(); // 🔥 이 줄을 추가하세요!
    _loadUnlockedThemes();
    _loadUnlockedAudioOptions();
    _loadUnlockedItems(); // 🔥 추가: 포인트 잠금 해제 아이템 로드

    FirebaseAuth.instance.authStateChanges().listen((user) {
      _loadFavorites();
      _loadCustomData(); // 🔥 여기도 추가!
      _loadUnlockedThemes();
      _loadUnlockedAudioOptions();
      _loadUnlockedItems(); // 🔥 추가
    });
  }

  // 🔥 추가된 부분 시작
  Future<void> _loadUnlockedItems() async {
    List<String> items = await _pointService.getUnlockedItems();
    setState(() {
      _unlockedItemIds = items.toSet();
    });
  }
  // 🔥 추가된 부분 끝

  void _refreshUser() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rewardedAd?.dispose();
    GlobalBgmManager.stopAllSound();
    _hidePreview();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      setState(() {
        _favorites = snapshot.docs
            .map((doc) => {...doc.data(), "docId": doc.id})
            .toList();
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      final String? favsJson = prefs.getString('my_favorites');

      if (favsJson != null) {
        setState(() {
          _favorites = List<Map<String, dynamic>>.from(jsonDecode(favsJson));
        });
      }
    }
  }

  Future<void> _deleteFavorite(int index) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final docId = _favorites[index]["docId"];

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(docId)
          .delete();
    }

    setState(() {
      _favorites.removeAt(index);
    });
    await _saveFavorites();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_favorites', jsonEncode(_favorites));
  }

  Future<void> _addFavorite(String name) async {
    final user = FirebaseAuth.instance.currentUser;
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
      "clockVideoName": globalClockVideoName.value,
    };
    if (user != null) {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .add(newFav);
      _favorites.add({
        ...newFav,
        "docId": docRef.id, // 🔥 추가
      });
    } else {
      // 비로그인 fallback
      _favorites.add(newFav);
      _saveFavorites();
    }

    setState(() {});
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
      globalClockVideoName.value = fav["clockVideoName"] ?? "사용 안 함";
    });
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
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                await _addFavorite(nameController.text.trim());
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
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            final double popupWidth = MediaQuery.of(context).size.width * 0.85;
            final double popupHeight =
                MediaQuery.of(context).size.height * 0.65;
            final int columns = 6;
            final double spacing = 12.0;

            // 1. 데이터 분류
            final solidOptions = _backgroundOptions
                .where((e) => e.video == null)
                .toList();
            final presetMediaOptions = _backgroundOptions
                .where((e) => e.video != null)
                .toList();

            // 2. [공통] 단색 및 기본 영상 그리드 빌더
            Widget buildGrid(List<ThemeItem> items) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: 1.0,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  bool isSelected = false;
                  bool isLocked = item.isPremium && !_unlockedSpecialThemes.contains(item.id);

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

                  if (item.color == Colors.transparent && title != "시계색")
                    return const SizedBox.shrink();

                  return GestureDetector(
                    onTap: () {
                      if (isLocked) {
                        _showSpecialMediaUnlockDialog(item, accentColor, dialogSetState);
                        return;
                      }
                      if (item.color != null) colorNotifier.value = item.color!;
                      if (title == "배경색")
                        globalBgVideoName.value = item.video ?? "사용 안 함";
                      else if (title == "시계색")
                        globalClockVideoName.value = item.video ?? "사용 안 함";
                      Navigator.pop(context);
                    },
                    onLongPressStart: (details) {
                      if (item.video != null)
                        _showPreview(context, item.video!);
                    },
                    onLongPressEnd: (details) => _hidePreview(),
                    onLongPressCancel: () => _hidePreview(),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: item.color,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: isSelected
                                  ? accentColor
                                  : Colors.grey.shade300,
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
                              ? const Icon(
                                  Icons.format_color_reset,
                                  color: Colors.grey,
                                  size: 20,
                                )
                              : null,
                        ),
                        if (item.video != null)
                          const Icon(
                            Icons.wallpaper,
                            color: Colors.white,
                            size: 20,
                          ),
                        if (isLocked)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        if (isLocked)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                        if (isLocked)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${item.unlockPoint}P",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
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
                    Text(
                      "$title 선택",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: [
                          // ✅ 1. 단색 리스트 (복구됨)
                          Text(
                            "단색",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          buildGrid(solidOptions),

                          // ✅ 2. 기본 제공 영상 (배경색일 때만 표시, 복구됨)
                          if (title == "배경색") ...[
                            const SizedBox(height: 24),
                            Text(
                              "스페셜",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            buildGrid(presetMediaOptions),
                          ],

                          // ✅ 3. 내 갤러리 사진 (슬롯 유지 버전)
                          const SizedBox(height: 24),
                          Text(
                            "내 사진",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              int currentSlots = title == "배경색"
                                  ? _unlockedBgMediaSlots
                                  : _unlockedClockMediaSlots;
                              List<String> currentList = title == "배경색"
                                  ? _localBgMediaPaths
                                  : _localClockMediaPaths;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: spacing,
                                  mainAxisSpacing: spacing,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: currentList.length + 1,
                                itemBuilder: (context, index) {
                                  if (index < currentList.length) {
                                    final path = currentList[index];
                                    bool isSelected = (title == "배경색" ? globalBgVideoName.value : globalClockVideoName.value) == path;
                                    return GestureDetector(
                                      onTap: () {
                                        if (title == "배경색") {
                                          globalBgVideoName.value = path;
                                        } else if (title == "시계색") {
                                          globalClockVideoName.value = path;
                                          if (globalClockColor.value == Colors.transparent) {
                                            globalClockColor.value = const Color.fromARGB(255, 185, 70, 70);
                                          }
                                        }
                                        Navigator.pop(context);
                                      },
                                      onLongPress: () => _confirmDeletion("사진", () {
                                        _deleteImage(title, index);
                                        dialogSetState(() {});
                                      }),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected ? accentColor : Colors.grey.shade300,
                                            width: isSelected ? 3.0 : 1.0,
                                          ),
                                          image: DecorationImage(
                                            image: kIsWeb ? NetworkImage(path) as ImageProvider : FileImage(File(path)),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    // + Button (Slot)
                                    bool isSlotLocked = currentList.length >= currentSlots;
                                    return GestureDetector(
                                      onTap: () {
                                        if (isSlotLocked) {
                                          _showMediaSlotUnlockDialog(title, accentColor, dialogSetState);
                                        } else {
                                          _pickLocalImage(title, dialogSetState: dialogSetState);
                                        }
                                      },
                                      onLongPress: currentSlots > currentList.length + 1
                                          ? () {
                                              _confirmDeletion("사진 슬롯", () {
                                                setState(() {
                                                  if (title == "배경색") _unlockedBgMediaSlots--;
                                                  else _unlockedClockMediaSlots--;
                                                });
                                                dialogSetState(() {});
                                                _updateSlotCount();
                                              }, isSlot: true);
                                            }
                                          : null,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey.shade300, width: 1.0),
                                            ),
                                            child: Icon(Icons.add_photo_alternate, color: Colors.grey.shade400),
                                          ),
                                          if (isSlotLocked)
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.35),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          if (isSlotLocked)
                                            Positioned(
                                              top: 4, right: 4,
                                              child: Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), shape: BoxShape.circle),
                                                child: const Icon(Icons.lock, color: Colors.white, size: 10),
                                              ),
                                            ),
                                          if (isSlotLocked)
                                            Positioned(
                                              bottom: 4,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(8)),
                                                child: Text("$_customPhotoSlotPrice" + "P", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ],
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
      },
    );
  }

  void _showAudioPickerDialog(
    String title,
    List<String> options,
    ValueNotifier<String> notifier,
    Color accentColor,
    Function(String) onPreview, {
    required String type,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final double popupWidth = screenWidth * 0.85;
        final double popupHeight = screenHeight * 0.6;
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            GlobalBgmManager.stopAllSound(); // 🔥 뒤로가기 시 소리 끄기
          },
          child: Dialog(
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
                          // 🌟 내부 구분선 색상 동기화
                          separatorBuilder: (context, index) => Divider(
                            color: accentColor.withOpacity(0.2),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final isSelected = option == currentValue;
                            final isLocked = _isAudioOptionLocked(
                              type,
                              options,
                              option,
                            );

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 4.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              tileColor: isSelected
                                  ? accentColor.withOpacity(0.1)
                                  : Colors.transparent,
                              leading: Icon(
                                type == "bgm"
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
                                  : isLocked
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.lock,
                                          size: 16,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${type == "alarm" ? _premiumAlarmPrice : _premiumBgmPrice}P",
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                              onTap: () {
                                final user = FirebaseAuth.instance.currentUser;

                                if (isLocked) {
                                  if (user == null) {
                                    return;
                                  }

                                  _showAudioUnlockDialog(
                                    type: type,
                                    option: option,
                                    accentColor: accentColor,
                                    notifier: notifier,
                                    onPreview: onPreview,
                                  );
                                  return;
                                }

                                notifier.value = option;
                                onPreview(option);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      GlobalBgmManager.stopAllSound(); // 🔥 추가
                      Navigator.pop(context);
                    },
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
    Function(String) onPreview, {
    required String type,
  }) {
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
              type: type,
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
    // 🔥 색상뿐만 아니라 배경/시계 사진이 바뀌는 것도 즉시 감지하여 100% 아이콘을 유지합니다.
    return AnimatedBuilder(
      animation: Listenable.merge([
        notifier,
        globalBgVideoName,
        globalClockVideoName,
      ]),
      builder: (context, _) {
        Color color = notifier.value;
        String videoName = "사용 안 함";

        if (title == "배경색") {
          videoName = globalBgVideoName.value;
        } else if (title == "시계색") {
          videoName = globalClockVideoName.value;
        }

        // 🔥 노을, 밤하늘 예외 처리 필수! (안 그러면 갤러리 사진으로 착각해 회색 네모가 됨)
        bool isLocalImage =
            videoName != "사용 안 함" &&
            videoName != "비 오는 밤 (Rain)" &&
            videoName != "벚꽃 (Cherry Blossom)" &&
            videoName != "노을 (Sunset)" &&
            videoName != "밤하늘 (Sky Moon)";

        // 영상이나 사진이 적용되어 있으면 무조건 아이콘 표시
        bool hasMedia = videoName != "사용 안 함";

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
                    // 로컬 갤러리 사진일 때만 회색으로, 내장 사진(노을 등)이면 주황색 유지!
                    color: color == Colors.transparent
                        ? Colors.transparent
                        : (isLocalImage ? Colors.grey : color),
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
                      : (hasMedia
                            ? const Icon(
                                Icons.image,
                                color: Colors.white,
                                size: 20,
                              )
                            : null),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // ---------------- 교체 끝 ----------------

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
            // 🔥 앱바 추가: 포인트 충전 버튼이 여기에 들어갑니다.
            appBar: AppBar(
              title: Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: uiAccentColor,
                ),
              ),
              backgroundColor: const Color(0xFFF9F9F9),
              elevation: 0,
              iconTheme: IconThemeData(color: uiAccentColor),
              actions: [
                // 🪙 상점으로 이동하는 버튼
                TextButton.icon(
                  onPressed: () {
                    // 포인트 상점 페이지로 화면 이동!
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PointShopPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.monetization_on, color: Colors.amber),
                  label: const Text(
                    '포인트 충전',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFF9F9F9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Divider(
                          height: 1,
                          color: uiAccentColor.withOpacity(0.3),
                        ),
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
            Icon(icon, color: color, size: size.width * 0.05),
            SizedBox(width: size.width * 0.03),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
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
          fontSize: (size.width * 0.035).clamp(11.0, 15.0),
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
              onPressed: () => Navigator.pop(context, {
                "email": email.text.trim(),
                "pw": pw.text.trim(),
                "type": "login",
              }),
              child: const Text("로그인"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, {
                "email": email.text.trim(),
                "pw": pw.text.trim(),
                "type": "signup",
              }),
              child: const Text("회원가입"),
            ),
          ],
        );
      },
    );
  }

  // ✅ [복구] 계정 섹션 위젯 (반응형 폰트 적용 완료)
  Widget _buildAccountSection(Color accentColor) {
    final size = MediaQuery.of(context).size;
    // 태블릿인지 확인 (너비 600 이상)
    final bool isTablet = size.width > 600;

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
                    await _loadFavorites();
                  }
                },
              ),
              SizedBox(height: size.height * 0.01),
              _loginButton("이메일 로그인", Icons.email, accentColor, () async {
                final result = await _showEmailDialog();
                if (result == null) return;
                final email = result["email"]!;
                final pw = result["pw"]!;
                final type = result["type"];
                if (type == "login" && (email.isEmpty || pw.isEmpty)) return;
                if (type == "signup") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SignUpPage()),
                  );
                } else {
                  final user = await AuthService.signInWithEmail(email, pw);
                  if (user != null) {
                    await FirebaseSettingsService.loadSettingsFromCloud();
                    await _loadFavorites();
                  }
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
                            // 🔥 반응형 폰트 크기: 태블릿에서는 최대 18로 제한
                            fontSize: (size.width * 0.04).clamp(14.0, 18.0),
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            int point = 0;
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data =
                                  snapshot.data!.data()
                                      as Map<String, dynamic>?;
                              point = data?['point'] ?? 0;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "포인트 : $point",
                                style: TextStyle(
                                  // 🔥 포인트 텍스트도 동일하게 제한
                                  fontSize: (size.width * 0.034).clamp(
                                    12.0,
                                    16.0,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: accentColor.withOpacity(0.9),
                                ),
                              ),
                            );
                          },
                        ),
                        if (!user.emailVerified) ...[
                          Text(
                            "이메일 인증 필요",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: (size.width * 0.03).clamp(10.0, 14.0),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () async {
                              final user = FirebaseAuth.instance.currentUser;
                              await user?.reload();
                              final refreshedUser =
                                  FirebaseAuth.instance.currentUser;
                              setState(() {
                                _user = refreshedUser;
                              });
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
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      globalBgVideoName.value = "사용 안 함";
                      globalClockVideoName.value = "사용 안 함";
                      setState(() {
                        _favorites.clear();
                        _localCustomPresets.clear();
                        _localBgMediaPaths.clear();
                        _localClockMediaPaths.clear();
                        _unlockedBgMediaSlots = 0;
                        _unlockedClockMediaSlots = 0;
                        _unlockedThemeSlots = 0;
                      });
                      await loadSettings();
                      await _loadFavorites();
                      setState(() {});
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
    bool showstopwatch = false;
    bool isLastItem = index == _tabTitles.length - 1;
    Widget sectionContent;

    if (index == 0) {
      sectionContent = _buildAccountSection(accentColor);
    } else if (index == 1) {
      sectionContent = Column(
        children: [
          if (_favorites.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                "현재 저장된 즐겨찾기가 없습니다.",
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
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  "취소",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await _deleteFavorite(i); // 🔥 핵심
                                  Navigator.pop(context);
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
      // ---------------- ✨ 여기서부터 통째로 교체 ✨ ----------------
    } else if (index == 2) {
      sectionContent = AnimatedBuilder(
        animation: Listenable.merge([
          globalBgColor,
          globalClockColor,
          globalDigitalColor,
          globalIndicatorColor,
          globalBgVideoName,
          globalClockVideoName, // 🔥 [핵심] 시계 사진 변화 감지!
        ]),
        builder: (context, child) {
          final solidPresets = _themePresets
              .where((t) => t.bgVideo == "사용 안 함" && t.clockVideo == "사용 안 함")
              .toList();
          final mediaPresets = _themePresets
              .where((t) => t.bgVideo != "사용 안 함" || t.clockVideo != "사용 안 함")
              .toList();

          // ---------------- ✨ 바꿀 코드 ✨ ----------------
          // ✅ 공통으로 사용할 프리셋 위젯 빌더
          Widget buildPresetItem(AppThemePreset theme, bool isSelected) {
            // 🔥 배경이 로컬 사진인지 체크
            bool isLocalBg =
                theme.bgVideo != "사용 안 함" &&
                theme.bgVideo != "비 오는 밤 (Rain)" &&
                theme.bgVideo != "벚꽃 (Cherry Blossom)" &&
                theme.bgVideo != "노을 (Sunset)" &&
                theme.bgVideo != "밤하늘 (Sky Moon)"; // 🔥 새 사진 이름 추가!
            // 🔥 시계가 로컬 사진인지 체크
            bool isLocalClock =
                theme.clockVideo != "사용 안 함" &&
                theme.clockVideo != "비 오는 밤 (Rain)" &&
                theme.clockVideo != "벚꽃 (Cherry Blossom)" &&
                theme.clockVideo != "노을 (Sunset)" &&
                theme.clockVideo != "밤하늘 (Sky Moon)"; // 🔥 새 사진 이름 추가!

            bool hasAnyMedia =
                theme.bgVideo != "사용 안 함" || theme.clockVideo != "사용 안 함";

            return GestureDetector(
              onTap: () {
                globalBgColor.value = theme.bg;
                globalClockColor.value = theme.clock;
                globalDigitalColor.value = theme.digital;
                globalIndicatorColor.value = theme.indicator;
                globalBgVideoName.value = theme.bgVideo;
                globalClockVideoName.value = theme.clockVideo;
              },
              // (미리보기 로직 생략...)
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.grey.shade300,
                    width: isSelected ? 3.0 : 1.0,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.5, 0.5],
                    // 🔥 로컬 사진 부위만 회색으로, 내장 테마는 원래 색상으로!
                    colors: [
                      isLocalBg ? Colors.grey : theme.bg,
                      isLocalClock ? Colors.grey : theme.clock,
                    ],
                  ),
                ),
                child: hasAnyMedia
                    ? const Icon(Icons.image, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "프리셋 선택",
                style: TextStyle(
                  fontSize: 16,
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "단색 테마",
                style: TextStyle(
                  fontSize: 13,
                  color: accentColor.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: solidPresets.map((t) {
                  bool isSelected =
                      globalBgColor.value == t.bg &&
                      globalClockColor.value == t.clock &&
                      globalDigitalColor.value == t.digital &&
                      globalIndicatorColor.value == t.indicator &&
                      globalBgVideoName.value == t.bgVideo &&
                      globalClockVideoName.value == t.clockVideo;
                  return buildPresetItem(t, isSelected);
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                "스페셜 테마",
                style: TextStyle(
                  fontSize: 13,
                  color: accentColor.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: mediaPresets.map((t) {
                  final bool isSelected =
                      globalBgColor.value == t.bg &&
                      globalClockColor.value == t.clock &&
                      globalDigitalColor.value == t.digital &&
                      globalIndicatorColor.value == t.indicator &&
                      globalBgVideoName.value == t.bgVideo &&
                      globalClockVideoName.value == t.clockVideo;

                  final bool isLocked =
                      t.isPremium && !_unlockedSpecialThemes.contains(t.id);

                  return GestureDetector(
                    onTap: () {
                      final user = FirebaseAuth.instance.currentUser;

                      if (user == null) {
                        return;
                      }

                      if (isLocked) {
                        _showThemeUnlockDialog(t);
                        return;
                      }

                      globalBgColor.value = t.bg;
                      globalClockColor.value = t.clock;
                      globalDigitalColor.value = t.digital;
                      globalIndicatorColor.value = t.indicator;
                      globalBgVideoName.value = t.bgVideo;
                      globalClockVideoName.value = t.clockVideo;
                    },
                    child: Stack(
                      children: [
                        buildPresetItem(t, isSelected),

                        if (isLocked)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                        if (isLocked)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ),

                        if (isLocked)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 5,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${t.unlockPoint}P",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                "커스텀 테마",
                style: TextStyle(
                  fontSize: 13,
                  color: accentColor.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: List.generate(_unlockedThemeSlots + 1, (index) {
                  if (index < _localCustomPresets.length) {
                    final t = _localCustomPresets[index];

                    bool isSelected =
                        globalBgColor.value == t.bg &&
                        globalClockColor.value == t.clock &&
                        globalDigitalColor.value == t.digital &&
                        globalIndicatorColor.value == t.indicator &&
                        globalBgVideoName.value == t.bgVideo &&
                        globalClockVideoName.value == t.clockVideo;

                    bool hasBgImage = t.bgVideo != "사용 안 함";
                    bool hasClockImage = t.clockVideo != "사용 안 함";

                    return GestureDetector(
                      onTap: () {
                        globalBgColor.value = t.bg;
                        globalClockColor.value = t.clock;
                        globalDigitalColor.value = t.digital;
                        globalIndicatorColor.value = t.indicator;
                        globalBgVideoName.value = t.bgVideo;
                        globalClockVideoName.value = t.clockVideo;
                      },
                      onLongPress: () =>
                          _confirmDeletion("커스텀 테마", () => _deleteTheme(index)),
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
                            colors: [
                              hasBgImage ? Colors.grey : t.bg,
                              hasClockImage ? Colors.grey : t.clock,
                            ],
                          ),
                        ),
                        child: (hasBgImage || hasClockImage)
                            ? const Icon(
                                Icons.image,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }

                  if (index < _unlockedThemeSlots) {
                    return GestureDetector(
                      onTap: _saveCurrentAsPresetLocal,
                      onLongPress:
                          _unlockedThemeSlots > _localCustomPresets.length
                          ? () {
                              _confirmDeletion("테마 슬롯", () {
                                setState(() {
                                  _unlockedThemeSlots--;
                                });

                                _updateSlotCount();
                              }, isSlot: true);
                            }
                          : null,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.grey.shade400,
                          size: 28,
                        ),
                      ),
                    );
                  }

                  return GestureDetector(
                    onTap: () {
                      final user = FirebaseAuth.instance.currentUser;

                      if (user == null) {
                        return;
                      }

                      _showCustomThemeSlotUnlockDialog(accentColor);
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.grey.shade400,
                            size: 28,
                          ),
                        ),

                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),

                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 5,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${_customThemeSlotPrice}P",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Divider(height: 1, color: accentColor.withOpacity(0.2)),
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
      // ---------------- 여기까지 ----------------
    } else if (index == 3) {
      sectionContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showstopwatch) ...[
            buildTwoOptionToggle(
              "모드 선택",
              "TMR",
              "SW",
              globalIsTimerMode,
              accentColor,
            ),
            Divider(
              color: accentColor.withOpacity(0.2),
              height: 16,
              thickness: 1,
            ),
          ],
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
          Divider(
            color: accentColor.withOpacity(0.2),
            height: 16,
            thickness: 1,
          ),
          CustomWheelPicker(
            title: "시계 표시",
            options: const ["BOTH", "ANALOG", "DIGITAL"],
            notifier: globalDisplayMode,
            accentColor: accentColor,
          ),
          Divider(
            color: accentColor.withOpacity(0.2),
            height: 16,
            thickness: 1,
          ),
          CustomWheelPicker(
            title: "숫자 표시",
            options: const ["NUMBER", "DOT", "NONE"],
            notifier: globalIndicatorMode,
            accentColor: accentColor,
          ),
          Divider(
            color: accentColor.withOpacity(0.2),
            height: 16,
            thickness: 1,
          ),
          CustomWheelPicker(
            title: "디지털 스타일",
            options: const ["DEFAULT", "SEGMENT", "FLIP"],
            notifier: globalDigitalStyle,
            accentColor: accentColor,
          ),
          Divider(
            color: accentColor.withOpacity(0.2),
            height: 16,
            thickness: 1,
          ),
          CustomWheelPicker(
            title: "폰트 크기",
            options: const ["SMALL", "MEDIUM", "LARGE"],
            notifier: globalDigitalFontSize,
            accentColor: accentColor,
          ),
          Divider(
            color: accentColor.withOpacity(0.2),
            height: 16,
            thickness: 1,
          ),
          CustomWheelPicker(
            title: "햅틱 진동",
            options: const ["NONE", "SOFT", "MEDIUM", "STRONG"],
            notifier: globalHapticIntensity,
            accentColor: accentColor,
            onSelected: _previewHapticIntensity,
          ),
        ],
      );
    } else if (index == 4) {
      sectionContent = ValueListenableBuilder<bool>(
        valueListenable: globalPomodoroMode,
        builder: (context, isPomodoroOn, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTwoOptionToggle(
                "뽀모도로 모드",
                "ON",
                "OFF",
                globalPomodoroMode,
                accentColor,
              ),
              if (isPomodoroOn) ...[
                Divider(
                  color: accentColor.withOpacity(0.2),
                  height: 24,
                  thickness: 1,
                ),
                Text(
                  "시간 및 횟수 설정",
                  style: TextStyle(
                    fontSize: 14,
                    color: accentColor.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                CustomWheelPicker(
                  title: "집중 시간",
                  options: List.generate(60, (i) => "${i + 1}분"),
                  notifier: globalPomodoroWorkTime,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 4),
                CustomWheelPicker(
                  title: "짧은 휴식",
                  options: List.generate(60, (i) => "${i + 1}분"),
                  notifier: globalPomodoroShortBreak,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 4),
                CustomWheelPicker(
                  title: "긴 휴식",
                  options: List.generate(60, (i) => "${i + 1}분"),
                  notifier: globalPomodoroLongBreak,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 4),
                CustomWheelPicker(
                  title: "긴 휴식 주기",
                  options: List.generate(10, (i) => "${i + 1}번"),
                  notifier: globalPomodoroCycleCount,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 4),
                CustomWheelPicker(
                  title: "최대 뽀모도로 횟수",
                  options: ["제한 없음", ...List.generate(20, (i) => "${i + 1}세션")],
                  notifier: globalPomodoroMaxSessions,
                  accentColor: accentColor,
                ),
                Divider(
                  color: accentColor.withOpacity(0.2),
                  height: 24,
                  thickness: 1,
                ),
                Text(
                  "자동 시작 옵션",
                  style: TextStyle(
                    fontSize: 14,
                    color: accentColor.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                buildTwoOptionToggle(
                  "집중 모드 자동시작",
                  "ON",
                  "OFF",
                  globalPomodoroAutoWork,
                  accentColor,
                ),
                buildTwoOptionToggle(
                  "휴식 모드 자동시작",
                  "ON",
                  "OFF",
                  globalPomodoroAutoBreak,
                  accentColor,
                ),
              ],
            ],
          );
        },
      );
    } else if (index == 5) {
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
          // 🔥 여기 추가
          buildTwoOptionToggle(
            "진동",
            "ON",
            "OFF",
            globalVibrationEnabled,
            accentColor,
          ),
          Divider(
            color: accentColor.withOpacity(0.2),
            height: 16,
            thickness: 1,
          ),
          audioPickerRow(
            "알림 방식",
            alarmOptions,
            globalAlarmSound,
            accentColor,
            (val) => GlobalBgmManager.previewAlarmSound(val),
            type: "alarm",
          ),
        ],
      );
    } else if (index == 6) {
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
          Divider(
            color: accentColor.withOpacity(0.2),
            height: 16,
            thickness: 1,
          ),
          audioPickerRow(
            "트랙 선택",
            bgmOptions,
            globalBgmTrack,
            accentColor,
            (val) => GlobalBgmManager.previewBgm(val),
            type: "bgm",
          ),
        ],
      );
    }
    // ✅ [고객 센터] 섹션 완성
    else if (index == 7) {
      sectionContent = Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.campaign, color: accentColor),
            title: const Text("공지사항"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoticePage(accentColor: accentColor),
              ),
            ),
          ),
          Divider(color: accentColor.withOpacity(0.1), height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.mail_outline, color: accentColor),
            title: const Text("피드백 및 버그 제보"),
            onTap: () => _showFeedbackDialog(accentColor),
          ),
          Divider(color: accentColor.withOpacity(0.1), height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.quiz_outlined, color: accentColor),
            title: const Text("자주 묻는 질문 (FAQ)"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FAQPage(accentColor: accentColor),
              ),
            ),
          ),
          Divider(color: accentColor.withOpacity(0.1), height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.school_outlined, color: accentColor),
            title: const Text("앱 튜토리얼 다시 보기"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pop(context); // 설정 창을 닫고 메인으로 돌아갑니다.
              // 🔥 글로벌 키를 사용해서 TimerPage의 startTutorial() 함수를 강제로 실행합니다.
              final timerState =
                  globalTimerPageKey.currentState as TimerAppPageState?;
              timerState?.startTutorial();
            },
          ),
          Divider(color: accentColor.withOpacity(0.1), height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline, color: accentColor),
            title: const Text("오픈소스 라이선스"),
            onTap: () =>
                showLicensePage(context: context, applicationName: "타이머"),
          ),
          const SizedBox(height: 8),
          Text(
            "버전 정보 1.0.0",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      );
    } else {
      sectionContent = const SizedBox();
    }

    return Column(
      key: _sectionKeys[index],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
          child: Row(
            children: [
              Text(
                _tabTitles[index],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              if (_tabTitles[index] == "뽀모도로")
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: InkWell(
                    onTap: () => _showPomodoroHelpDialog(accentColor),
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(
                      Icons.help_outline,
                      color: accentColor.withOpacity(0.7),
                      size: 22,
                    ),
                  ),
                ),
            ],
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(
              color: accentColor.withOpacity(0.2),
              thickness: 1.2,
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
                if (pw.text != pwConfirm.text) return;
                final user = await AuthService.signUpWithEmail(
                  email.text.trim(),
                  pw.text.trim(),
                );
                if (user != null) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("회원가입 완료"),
                      content: const Text("회원가입에 성공했습니다"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text("확인"),
                        ),
                      ],
                    ),
                  );
                } else {
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
                            if (widget.onSelected != null)
                              widget.onSelected!(widget.options[index]);
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

class MediaPreviewWidget extends StatefulWidget {
  final String videoName;
  const MediaPreviewWidget({super.key, required this.videoName});

  @override
  State<MediaPreviewWidget> createState() => _MediaPreviewWidgetState();
}

class _MediaPreviewWidgetState extends State<MediaPreviewWidget> {
  VideoPlayerController? _controller;
  bool _isVideo = false;
  String _assetPath = "";
  bool _isNetwork = false; // 🔥 네트워크 파일 여부 체크

  @override
  void initState() {
    super.initState();

    if (widget.videoName.startsWith("http")) {
      // ✅ 갤러리에서 올린 파이어베이스 URL인 경우
      _assetPath = widget.videoName;
      _isNetwork = true;
      // URL이나 메타데이터에 mp4가 있으면 비디오로 간주 (임시 처리)
      _isVideo = _assetPath.contains(".mp4") || _assetPath.contains("video");

      if (_isVideo) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(_assetPath))
          ..initialize().then((_) {
            _controller!.setVolume(0.0);
            _controller!.setLooping(true);
            _controller!.play();
            if (mounted) setState(() {});
          });
      }
    } else {
      // ✅ 기존 에셋 파일인 경우
      if (widget.videoName == "비 오는 밤 (Rain)") {
        _assetPath = 'assets/video/rainwindow.mp4';
        _isVideo = true;
      } else if (widget.videoName == "벚꽃 (Cherry Blossom)") {
        _assetPath = 'assets/video/sakura.mp4';
        _isVideo = true;
      } else if (widget.videoName == "노을 (Sunset)") {
        _assetPath = 'assets/image/sunset.jpg'; // 🔥 노을 사진 경로
        _isVideo = false; // 사진이므로 false
      } else if (widget.videoName == "밤하늘 (Sky Moon)") {
        _assetPath = 'assets/image/sky_moon.jpg'; // 🔥 밤하늘 사진 경로
        _isVideo = false; // 사진이므로 false
      }

      if (_isVideo && _assetPath.isNotEmpty) {
        _controller = VideoPlayerController.asset(_assetPath)
          ..initialize().then((_) {
            _controller!.setVolume(0.0);
            _controller!.setLooping(true);
            _controller!.play();
            if (mounted) setState(() {});
          });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // _MediaPreviewWidgetState 의 build 부분
  @override
  Widget build(BuildContext context) {
    if (_assetPath.isEmpty)
      return const Center(
        child: Text("파일을 찾을 수 없습니다.", style: TextStyle(color: Colors.white)),
      );

    // ✅ 로컬 기기의 파일 경로인지 확인 (앱 내부 경로는 보통 '/' 로 시작함)
    bool isLocalFile = _assetPath.startsWith('/');

    return Stack(
      children: [
        Positioned.fill(
          child: _isVideo
              ? (_controller != null && _controller!.value.isInitialized)
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
              : (isLocalFile
                    ? Image.file(
                        File(_assetPath),
                        fit: BoxFit.cover,
                      ) // 🔥 로컬 기기 파일
                    : (_isNetwork
                          ? Image.network(
                              _assetPath,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) =>
                                  progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                            )
                          : Image.asset(
                              _assetPath,
                              fit: BoxFit.cover,
                            ))), // 🔥 기존 에셋 파일
        ),
      ],
    );
  }
}

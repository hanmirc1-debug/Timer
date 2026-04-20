import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/shared_design.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

class FirebaseSettingsService {
  static final _db = FirebaseFirestore.instance;

  static Timer? _debounce;

  static void saveSettingsDebounced() {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () {
      saveSettingsToCloud(); // 👈 괄호 꼭 추가
    });
  }

  static Future<void> saveSettingsToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print("🔥 PROJECT ID: ${Firebase.app().options.projectId}"); // 👈 여기 추가
    print("🔥 Firebase 저장 실행됨");
    try {
      await _db.collection("users").doc(user.uid).set({
        "displayMode": globalDisplayMode.value,
        "timerMax": globalTimerMaxSeconds.value,
        "bgColor": globalBgColor.value.value,
        "clockColor": globalClockColor.value.value,
        "digitalColor": globalDigitalColor.value.value,
        "indicatorColor": globalIndicatorColor.value.value,
        "alarmEnabled": globalAlarmEnabled.value,
        "alarmSound": globalAlarmSound.value,
        "bgmEnabled": globalBgmEnabled.value,
        "bgmTrack": globalBgmTrack.value,
      }, SetOptions(merge: true));
      print("🔥 Firebase 저장 성공");
    } catch (e) {
      print("🔥 Firebase 저장 실패: $e");
    }
  }

  static Future<void> loadSettingsFromCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await _db.collection("users").doc(user.uid).get();

    if (!doc.exists) return;

    final data = doc.data()!;
    globalDisplayMode.value = data["displayMode"] ?? globalDisplayMode.value;

    globalTimerMaxSeconds.value =
        data["timerMax"] ?? globalTimerMaxSeconds.value;

    if (data["bgColor"] is int) {
      globalBgColor.value = Color(data["bgColor"]);
    }

    if (data["clockColor"] is int) {
      globalClockColor.value = Color(data["clockColor"]);
    }

    if (data["digitalColor"] is int) {
      globalDigitalColor.value = Color(data["digitalColor"]);
    }

    if (data["indicatorColor"] is int) {
      globalIndicatorColor.value = Color(data["indicatorColor"]);
    }

    globalAlarmEnabled.value = data["alarmEnabled"] ?? globalAlarmEnabled.value;

    globalAlarmSound.value = data["alarmSound"] ?? globalAlarmSound.value;

    globalBgmEnabled.value = data["bgmEnabled"] ?? globalBgmEnabled.value;

    globalBgmTrack.value = data["bgmTrack"] ?? globalBgmTrack.value;
  }
}

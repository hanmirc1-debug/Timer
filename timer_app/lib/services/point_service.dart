import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PointService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. 현재 유저의 포인트 스트림 (UI에서 실시간으로 보여주기 위해 사용)
  Stream<int> get pointStream {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (doc.exists && doc.data()!.containsKey('point')) {
        return doc.data()!['point'] as int;
      }
      return 0;
    });
  }

  // 2. 현재 유저의 포인트 단발성 조회
  Future<int> getCurrentPoint() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data()!.containsKey('point')) {
      return doc.data()!['point'] as int;
    }
    return 0;
  }

  // 3. 아이템 잠금 해제 (트랜잭션 사용 - 중복 차감 방지)
  Future<bool> unlockItem(String itemId, int price) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    final userRef = _firestore.collection('users').doc(user.uid);
    final unlockedItemRef = userRef.collection('unlockedItems').doc(itemId);

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. 이미 해제된 아이템인지 확인
        final unlockedSnapshot = await transaction.get(unlockedItemRef);
        if (unlockedSnapshot.exists) {
          throw Exception("이미 잠금 해제된 아이템입니다.");
        }

        // 2. 현재 포인트 확인
        final userSnapshot = await transaction.get(userRef);
        int currentPoint = 0;
        if (userSnapshot.exists && userSnapshot.data()!.containsKey('point')) {
          currentPoint = userSnapshot.data()!['point'] as int;
        }

        // 3. 포인트 부족 확인
        if (currentPoint < price) {
          throw Exception("포인트가 부족합니다.");
        }

        // 4. 포인트 차감 및 아이템 잠금 해제 기록 저장
        transaction.set(userRef, {'point': currentPoint - price}, SetOptions(merge: true));
        transaction.set(unlockedItemRef, {
          'unlockedAt': FieldValue.serverTimestamp(),
          'pricePaid': price,
        });
      });
      return true; // 성공
    } catch (e) {
      print("아이템 해제 실패: $e");
      rethrow; // 에러를 UI로 던져서 팝업을 띄울 수 있게 함
    }
  }
}
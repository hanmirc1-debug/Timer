import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PointPurchaseService {
  // 싱글톤 패턴 적용
  static final PointPurchaseService _instance = PointPurchaseService._internal();
  factory PointPurchaseService() => _instance;
  PointPurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // 판매할 상품 ID 목록 (구글 플레이콘솔 / 애플 앱스토어에 등록된 ID와 일치해야 함)
  final Set<String> _productIds = {
    'point_1000',
    'point_3300',
    'point_6000',
    'point_12000',
  };

  // UI에 전달할 상태 변수들
  bool isAvailable = false;
  List<ProductDetails> products = [];
  Function(String)? onPurchaseMessage; // UI에 메시지를 띄우기 위한 콜백

  // 1. 초기화 (main.dart 또는 스플래시 화면에서 호출해야 함)
  Future<void> init() async {
    isAvailable = await _iap.isAvailable();
    if (isAvailable) {
      await _loadProducts();
      // 결제 스트림 리스너 등록
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription.cancel(),
        onError: (error) {
          print("결제 스트림 에러: $error");
        },
      );
    }
  }

  // 2. 상품 정보 불러오기
  Future<void> _loadProducts() async {
    final ProductDetailsResponse response = await _iap.queryProductDetails(_productIds);
    if (response.notFoundIDs.isNotEmpty) {
      print("찾을 수 없는 상품 ID: ${response.notFoundIDs}");
    }
    products = response.productDetails;
    // 가격순으로 정렬
    products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
  }

  // 3. 결제 시작 함수 (UI에서 버튼 누를 때 호출)
  void buyPoint(ProductDetails product) {
    final user = _auth.currentUser;
    if (user == null) {
      onPurchaseMessage?.call("로그인이 필요합니다.");
      return;
    }
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    // 소모성 아이템(포인트)이므로 buyConsumable 사용
    _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
  }

  // 4. 결제 스트림 처리 (가장 중요한 부분)
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        onPurchaseMessage?.call("결제 진행 중...");
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        onPurchaseMessage?.call("결제 실패: ${purchaseDetails.error?.message}");
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        onPurchaseMessage?.call("결제가 취소되었습니다.");
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // 결제 성공! 서버(Firestore)에 포인트 지급
        _verifyAndGrantPoints(purchaseDetails);
      }

      // 에러가 나거나 성공했거나 처리가 끝났으면 complete 호출
      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  // 5. Firestore 트랜잭션을 이용한 안전한 포인트 지급 (중복 지급 방지)
  Future<void> _verifyAndGrantPoints(PurchaseDetails purchaseDetails) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final purchaseId = purchaseDetails.purchaseID ?? purchaseDetails.transactionDate;
    if (purchaseId == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final purchaseRecordRef = userRef.collection('pointPurchases').doc(purchaseId);

    // 상품 ID에 따른 포인트 부여량 설정
    int grantedPoints = 0;
    switch (purchaseDetails.productID) {
      case 'point_1000': grantedPoints = 1000; break;
      case 'point_3300': grantedPoints = 3300; break;
      case 'point_6000': grantedPoints = 6000; break;
      case 'point_12000': grantedPoints = 12000; break;
      default: return;
    }

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. 이미 처리된 영수증인지 확인 (중복 방지)
        final recordSnapshot = await transaction.get(purchaseRecordRef);
        if (recordSnapshot.exists) {
          print("이미 지급 완료된 결제 건입니다.");
          return; // 이미 지급됨
        }

        // 2. 현재 포인트 읽기
        final userSnapshot = await transaction.get(userRef);
        int currentPoint = 0;
        if (userSnapshot.exists && userSnapshot.data()!.containsKey('point')) {
          currentPoint = userSnapshot.data()!['point'] as int;
        }

        // 3. 포인트 증가 및 결제 기록 저장
        transaction.set(userRef, {'point': currentPoint + grantedPoints}, SetOptions(merge: true));
        transaction.set(purchaseRecordRef, {
          'productId': purchaseDetails.productID,
          'grantedPoints': grantedPoints,
          'purchaseDate': FieldValue.serverTimestamp(),
          'status': 'completed',
        });
      });
      onPurchaseMessage?.call("$grantedPoints P가 지급되었습니다!");
    } catch (e) {
      print("포인트 지급 중 오류 발생: $e");
      onPurchaseMessage?.call("포인트 지급 지연. 고객센터로 문의해주세요.");
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
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
    'point_3000',
    'point_5000',
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
      _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    bool grantSuccess = false;

    if (purchaseDetails.status == PurchaseStatus.pending) {
      onPurchaseMessage?.call("결제 진행 중...");
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      onPurchaseMessage?.call("결제 실패: ${purchaseDetails.error?.message}");
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      onPurchaseMessage?.call("결제가 취소되었습니다.");
    } else if (purchaseDetails.status == PurchaseStatus.purchased ||
               purchaseDetails.status == PurchaseStatus.restored) {
      // 🔥 결제 성공! 서버(Firestore)에 포인트 지급 (완료될 때까지 기다림)
      grantSuccess = await _verifyAndGrantPoints(purchaseDetails);
    }

    // 🔥 콘텐츠 지급이 성공(grantSuccess)했을 때만 완료(Consume) 처리!
    if (purchaseDetails.pendingCompletePurchase) {
      if (purchaseDetails.status != PurchaseStatus.purchased && purchaseDetails.status != PurchaseStatus.restored) {
        // 에러나 취소 상태면 무조건 완료 처리해서 대기 큐에서 제거
        await _iap.completePurchase(purchaseDetails);
      } else if (grantSuccess) {
        // 정상 결제 건은 파이어베이스에 포인트가 완벽히 들어간 경우에만 소비 처리
        await _iap.completePurchase(purchaseDetails);
      }
    }
  }

  // 5. Firestore 트랜잭션을 이용한 안전한 포인트 지급 (중복 지급 방지)
  Future<bool> _verifyAndGrantPoints(PurchaseDetails purchaseDetails) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final purchaseId = purchaseDetails.purchaseID ?? purchaseDetails.transactionDate;
    if (purchaseId == null) return false;

    final userRef = _firestore.collection('users').doc(user.uid);
    final purchaseRecordRef = userRef.collection('pointPurchases').doc(purchaseId);

    // 상품 ID에 따른 포인트 부여량 설정
    int grantedPoints = 0;
    switch (purchaseDetails.productID) {
      case 'point_1000': grantedPoints = 1000; break;
      case 'point_3000': grantedPoints = 3000; break;
      case 'point_5000': grantedPoints = 5000; break;
      default: return false; // 등록되지 않은 상품
    }

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. 이미 처리된 영수증인지 확인 (중복 방지)
        final recordSnapshot = await transaction.get(purchaseRecordRef);
        if (recordSnapshot.exists) {
          print("이미 지급 완료된 결제 건입니다.");
          return; // 트랜잭션 종료
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
      return true; // 지급 성공!
    } catch (e) {
      print("포인트 지급 중 오류 발생: $e");
      onPurchaseMessage?.call("포인트 지급 지연. 고객센터로 문의해주세요.");
      return false; // 지급 실패 (Consume 되지 않고 다음 접속 시 재시도됨)
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
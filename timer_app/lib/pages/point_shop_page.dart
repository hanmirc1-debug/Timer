import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/point_purchase_service.dart';
import '../services/point_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PointShopPage extends StatefulWidget {
  const PointShopPage({super.key});

  @override
  State<PointShopPage> createState() => _PointShopPageState();
}

class _PointShopPageState extends State<PointShopPage> {
  final PointPurchaseService _purchaseService = PointPurchaseService();
  final PointService _pointService = PointService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initStore();
    
    // 구매 진행 중 메시지를 스낵바로 띄우기 위한 콜백 연결
    _purchaseService.onPurchaseMessage = (message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
        );
      }
    };
  }

  Future<void> _initStore() async {
    // 상품 목록 로드 (앱 시작 시 미리 로드했다면 생략 가능)
    if (_purchaseService.products.isEmpty) {
       await _purchaseService.init();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // 앱 배경색에 맞춤
      appBar: AppBar(
        title: const Text('포인트 상점', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: user == null
          ? const Center(
              child: Text(
                '로그인 후 이용 가능합니다.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : Column(
              children: [
                _buildPointHeader(),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                      : _buildProductList(),
                ),
              ],
            ),
    );
  }

  // 상단 내 포인트 보여주는 영역 (StreamBuilder로 실시간 반영)
  Widget _buildPointHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('내 포인트', style: TextStyle(color: Colors.white70, fontSize: 18)),
          StreamBuilder<int>(
            stream: _pointService.pointStream,
            builder: (context, snapshot) {
              int point = snapshot.data ?? 0;
              return Text(
                '$point P',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 스토어에 등록된 상품 목록 표시
  Widget _buildProductList() {
    if (!_purchaseService.isAvailable) {
      return const Center(
        child: Text('스토어에 연결할 수 없습니다.', style: TextStyle(color: Colors.white)),
      );
    }

    if (_purchaseService.products.isEmpty) {
      return const Center(
        child: Text('판매 중인 상품이 없습니다.', style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _purchaseService.products.length,
      itemBuilder: (context, index) {
        ProductDetails product = _purchaseService.products[index];
        
        // title에서 앱 이름 등이 붙어 나오는 경우가 있어 가공
        String displayTitle = product.title.split('(').first.trim();

        return Card(
          color: const Color(0xFF2C2C2E),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.stars, color: Colors.amber, size: 36),
            title: Text(displayTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(product.description, style: const TextStyle(color: Colors.white54)),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => _purchaseService.buyPoint(product),
              child: Text(product.price, style: const TextStyle(color: Colors.white)),
            ),
          ),
        );
      },
    );
  }
}
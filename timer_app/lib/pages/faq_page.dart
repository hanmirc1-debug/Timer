import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  final Color accentColor;

  const FAQPage({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("자주 묻는 질문", 
          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQItem("광고가 나오지 않아요.", "네트워크 상태가 불안정하거나 광고 물량이 일시적으로 부족할 수 있습니다. 잠시 후 다시 시도해 주세요."),
          _buildFAQItem("포인트는 어디에 쓰나요?", "포인트는 추후 출시될 프리미엄 테마나 특별한 BGM을 영구 소장하는 데 사용될 예정입니다."),
          _buildFAQItem("데이터가 초기화되었어요.", "로그인 상태를 확인해 주세요. 게스트 모드일 경우 앱 삭제 시 데이터가 유지되지 않을 수 있으니 계정 연동을 추천드립니다."),
          _buildFAQItem("뽀모도로 모드 자동 시작이 안 돼요.", "설정 > 뽀모도로 섹션에서 '자동 시작 옵션'이 켜져 있는지 확인해 주세요."),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        shape: const Border(), // 하단 구분선 제거
        title: Text(question, 
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(answer, 
              style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }
}
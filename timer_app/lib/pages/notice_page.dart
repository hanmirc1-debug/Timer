import 'package:flutter/material.dart';
import '../notice/notice.dart'; // ✅ 파일명이 notice.dart 인지 꼭 확인하세요!

class NoticePage extends StatelessWidget {
  final Color accentColor;
  const NoticePage({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("공지사항", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        foregroundColor: accentColor,
        backgroundColor: Colors.white,
        elevation: 0,
        // ✅ 뒤로가기 버튼 추가
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: notices.isEmpty 
        ? const Center(child: Text("등록된 공지사항이 없습니다."))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notice = notices[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text(notice.date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(notice.content, style: const TextStyle(height: 1.5, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
class NoticeItem {
  final String title;
  final String content;
  final String date;

  NoticeItem({
    required this.title,
    required this.content,
    required this.date,
  });
}

// ✅ 변수 이름을 'notices'로 설정하여 NoticePage와 맞춥니다.
final List<NoticeItem> notices = [
  NoticeItem(
    title: "타이머 앱 EXAMPLE 출시 안내",
    content: "안녕하세요! 심플하고 강력한 타이머 앱이 EXAMPLE용으로 으로 출시되었습니다. 많은 이용 부탁드립니다.",
    date: "2026.08.08",
  ),
];
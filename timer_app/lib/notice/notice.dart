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
    title: "타이머 앱 정식 출시 안내 example",
    content: "안녕하세요! 심플하고 강력한 타이머 앱이 정식으로 출시되었습니다. 많은 이용 부탁드립니다.",
    date: "2024.05.20",
  ),
  NoticeItem(
    title: "뽀모도로 모드 사용 팁 example ",
    content: "설정에서 집중 시간과 휴식 시간을 자유롭게 조절하여 나만의 집중 리듬을 찾아보세요!",
    date: "2024.05.15",
  ),
];
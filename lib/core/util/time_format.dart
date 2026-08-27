// 시각·기간 표시용 포맷 유틸.

/// DateTime → "오후 3:02" 형식(로컬 시각).
String formatKoreanTime(DateTime t) {
  final l = t.toLocal();
  final ampm = l.hour < 12 ? '오전' : '오후';
  final h12 = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final mm = l.minute.toString().padLeft(2, '0');
  return '$ampm $h12:$mm';
}

/// yyyy-MM 월 키.
String monthKey(DateTime d) {
  final l = d.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}';
}

/// yyyy-MM-dd 날짜 키.
String dateKey(DateTime d) {
  final l = d.toLocal();
  final mm = l.month.toString().padLeft(2, '0');
  final dd = l.day.toString().padLeft(2, '0');
  return '${l.year}-$mm-$dd';
}

/// Duration → "2시간 30분" / "45분".
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h > 0 && m > 0) return '$h시간 $m분';
  if (h > 0) return '$h시간';
  return '$m분';
}

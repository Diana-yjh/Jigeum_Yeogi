// 시각·기간 표시용 포맷 유틸.

/// 요일 코드(월~일). Firestore scheduledDays에 저장되는 값.
const weekdayCodes = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

/// 요일 한글 라벨(월~일).
const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

/// DateTime → 요일 코드('mon'..'sun').
String weekdayCodeOf(DateTime d) => weekdayCodes[d.toLocal().weekday - 1];

/// DateTime → 요일 한글('월'..'일').
String weekdayLabelOf(DateTime d) => weekdayLabels[d.toLocal().weekday - 1];

/// 스케줄용 30분 단위 시간 슬롯("HH:mm"). 08:00 ~ 22:00.
List<String> get scheduleTimeSlots {
  final slots = <String>[];
  for (var m = 8 * 60; m <= 22 * 60; m += 30) {
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final mm = (m % 60).toString().padLeft(2, '0');
    slots.add('$h:$mm');
  }
  return slots;
}

/// "HH:mm"(24시간) → "오후 3:00" 형식.
String formatHhmm(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts.first) ?? 0;
  final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  final ampm = h < 12 ? '오전' : '오후';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$ampm $h12:${m.toString().padLeft(2, '0')}';
}

/// DateTime → "14:30" 24시간 형식(로컬).
String clock(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

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

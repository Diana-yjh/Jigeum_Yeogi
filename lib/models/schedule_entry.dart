/// 수업 유형 — 정규 / 보충.
enum ClassType { regular, makeup }

extension ClassTypeX on ClassType {
  String get code => this == ClassType.makeup ? 'makeup' : 'regular';
  String get label => this == ClassType.makeup ? '보충' : '정규';
}

ClassType classTypeFrom(String? code) =>
    code == 'makeup' ? ClassType.makeup : ClassType.regular;

/// 한 요일의 스케줄 항목 — 등원 시각 + 수업 유형.
class ScheduleEntry {
  final String time; // "HH:mm" (30분 단위), 미설정이면 ''
  final ClassType type;

  const ScheduleEntry({required this.time, this.type = ClassType.regular});

  /// Firestore 값 파싱. 신규는 {time,type} 맵, 레거시는 "HH:mm" 문자열.
  factory ScheduleEntry.fromValue(dynamic v) {
    if (v is Map) {
      return ScheduleEntry(
        time: (v['time'] as String?) ?? '',
        type: classTypeFrom(v['type'] as String?),
      );
    }
    if (v is String) {
      return ScheduleEntry(time: v); // 레거시: 시간 문자열만
    }
    return const ScheduleEntry(time: '');
  }

  Map<String, dynamic> toMap() => {'time': time, 'type': type.code};

  ScheduleEntry copyWith({String? time, ClassType? type}) =>
      ScheduleEntry(time: time ?? this.time, type: type ?? this.type);
}

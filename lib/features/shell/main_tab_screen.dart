import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/models/user_role.dart';
import 'package:jigeum_yeogi/features/home/teacher_home_screen.dart';
import 'package:jigeum_yeogi/features/home/parent_home_screen.dart';
import 'package:jigeum_yeogi/features/attendance/attendance_screen.dart';
import 'package:jigeum_yeogi/features/calendar/parent_calendar_screen.dart';
import 'package:jigeum_yeogi/features/schedule/schedule_screen.dart';
import 'package:jigeum_yeogi/features/settings/settings_screen.dart';

/// 역할별 하단 탭 셸.
/// - 선생님: 홈 / 출석 / 스케줄 / 설정
/// - 학부모: 홈 / 달력 / 설정
class MainTabScreen extends ConsumerStatefulWidget {
  final Role role;
  const MainTabScreen({super.key, required this.role});

  @override
  ConsumerState<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends ConsumerState<MainTabScreen> {
  int _index = 0;

  /// 역할에 따라 탭 구성을 반환한다.
  List<_TabItem> get _tabs {
    if (widget.role == Role.teacher) {
      return const [
        _TabItem(Icons.home_outlined, Icons.home, '홈', TeacherHomeScreen()),
        _TabItem(Icons.check_circle_outline, Icons.check_circle, '출석',
            AttendanceScreen()),
        _TabItem(Icons.event_note_outlined, Icons.event_note, '스케줄',
            ScheduleScreen()),
        _TabItem(Icons.settings_outlined, Icons.settings, '설정',
            SettingsScreen()),
      ];
    }
    return const [
      _TabItem(Icons.home_outlined, Icons.home, '홈', ParentHomeScreen()),
      _TabItem(Icons.calendar_month_outlined, Icons.calendar_month, '달력',
          ParentCalendarScreen()),
      _TabItem(Icons.settings_outlined, Icons.settings, '설정', SettingsScreen()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [for (final t in tabs) t.screen],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget screen;
  const _TabItem(this.icon, this.selectedIcon, this.label, this.screen);
}

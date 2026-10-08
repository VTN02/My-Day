import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/task_card.dart';

/// Monthly Calendar Screen Foundation.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  int _selectedDay = DateTime.now().day;

  final List<String> _weekdays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkCardSurface
        : AppColors.lightCardSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    // Days in current month
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              eyebrow: 'Schedule & Time',
              title: '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
              subtitle: 'Select any day to inspect planned tasks',
              trailing: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: _previousMonth,
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Weekday headers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _weekdays.map((day) {
                        return SizedBox(
                          width: 36,
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Days grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 6,
                            childAspectRatio: 1.0,
                          ),
                      itemCount: startingWeekday + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < startingWeekday) {
                          return const SizedBox.shrink();
                        }
                        final dayNumber = index - startingWeekday + 1;
                        final isSelected = dayNumber == _selectedDay;
                        final isToday =
                            dayNumber == DateTime.now().day &&
                            _currentMonth.month == DateTime.now().month &&
                            _currentMonth.year == DateTime.now().year;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = dayNumber),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryIndigo
                                  : (isToday
                                        ? (isDark
                                              ? AppColors.darkSoftIndigo
                                              : AppColors.lightSoftIndigo)
                                        : Colors.transparent),
                              borderRadius: AppRadius.mdRadius,
                              border: isToday && !isSelected
                                  ? Border.all(
                                      color: AppColors.primaryIndigo,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                              ? AppColors.darkPrimaryText
                                              : AppColors.lightPrimaryText),
                                  ),
                                ),
                                if (dayNumber % 3 == 0) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.accentCyan,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SectionHeader(
                  title:
                      'Tasks for ${_monthName(_currentMonth.month)} $_selectedDay',
                  subtitle: '2 tasks scheduled for this day',
                ),
                TaskCard(
                  title: 'Project architecture review meeting',
                  category: 'Work',
                  dueTime: '11:00 AM',
                  priority: 'high',
                  isCompleted: true,
                  onToggle: (v) {},
                ),
                TaskCard(
                  title: 'Evening gym and flexibility routine',
                  category: 'Health',
                  dueTime: '06:00 PM',
                  priority: 'medium',
                  isCompleted: false,
                  onToggle: (v) {},
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

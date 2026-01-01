import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// Time range selector for hot/popular pages with iOS 26 liquid glass style
class TimeRangeSelector extends StatelessWidget {
  final String selected;
  final List<String> options;
  final Function(String) onChanged;
  final DateTime? customDate;
  final Function(DateTime?)? onDateSelected;

  const TimeRangeSelector({
    super.key,
    required this.selected,
    required this.options,
    required this.onChanged,
    this.customDate,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        CupertinoColors.white.withValues(alpha: 0.12),
                        CupertinoColors.white.withValues(alpha: 0.06),
                      ]
                    : [
                        CupertinoColors.white.withValues(alpha: 0.8),
                        CupertinoColors.white.withValues(alpha: 0.6),
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.12)
                    : CupertinoColors.white.withValues(alpha: 0.5),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? CupertinoColors.black.withValues(alpha: 0.3)
                      : CupertinoColors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Time range options
                ...options.map((option) {
                  final isSelected = option == selected && customDate == null;
                  return GestureDetector(
                    onTap: () {
                      onDateSelected?.call(null); // Clear custom date
                      onChanged(option);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.8),
                                        CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.6),
                                      ]
                                    : [
                                        CupertinoTheme.of(context).primaryColor,
                                        CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.85),
                                      ],
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        _formatLabel(option),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? CupertinoColors.white
                              : isDark
                                  ? CupertinoColors.white.withValues(alpha: 0.7)
                                  : CupertinoColors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  );
                }),
                // Calendar button
                if (onDateSelected != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showDatePicker(context, isDark),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: customDate != null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.8),
                                        CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.6),
                                      ]
                                    : [
                                        CupertinoTheme.of(context).primaryColor,
                                        CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.85),
                                      ],
                              )
                            : null,
                        boxShadow: customDate != null
                            ? [
                                BoxShadow(
                                  color: CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.calendar,
                            size: 16,
                            color: customDate != null
                                ? CupertinoColors.white
                                : isDark
                                    ? CupertinoColors.white.withValues(alpha: 0.7)
                                    : CupertinoColors.black.withValues(alpha: 0.6),
                          ),
                          if (customDate != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MMM d').format(customDate!),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  void _showDatePicker(BuildContext context, bool isDark) {
    DateTime selectedDate = customDate ?? DateTime.now();
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark 
                        ? CupertinoColors.white.withValues(alpha: 0.1)
                        : CupertinoColors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDateSelected?.call(null);
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: CupertinoColors.destructiveRed,
                      ),
                    ),
                  ),
                  Text(
                    'Select Date',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDateSelected?.call(selectedDate);
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selectedDate,
                maximumDate: DateTime.now(),
                minimumDate: DateTime(2007), // e621 started around 2007
                onDateTimeChanged: (date) {
                  selectedDate = date;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLabel(String option) {
    switch (option) {
      case 'day':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      default:
        return option;
    }
  }
}

/// View toggle button (grid/list)
class ViewToggleButton extends StatelessWidget {
  final bool isGrid;
  final VoidCallback onToggle;

  const ViewToggleButton({
    super.key,
    required this.isGrid,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(12),
      onPressed: onToggle,
      child: Icon(
        isGrid ? CupertinoIcons.list_bullet : CupertinoIcons.square_grid_2x2,
        size: 22,
      ),
    );
  }
}

/// Segmented control wrapper
class SegmentedSelector<T extends Object> extends StatelessWidget {
  final Map<T, String> segments;
  final T selected;
  final Function(T) onChanged;

  const SegmentedSelector({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<T>(
      groupValue: selected,
      children: segments.map(
        (key, value) => MapEntry(
          key,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(value),
          ),
        ),
      ),
      onValueChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

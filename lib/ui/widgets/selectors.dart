import 'package:flutter/cupertino.dart';

/// Simple time range selector for hot/popular pages
class DesktopTimeRangeSelector extends StatelessWidget {
  const DesktopTimeRangeSelector({
    super.key,
    required this.selected,
    required this.options,
    required this.onChanged,
    this.customDate,
    this.onDateSelected,
  });

  final String selected;
  final List<String> options;
  final void Function(String) onChanged;
  final DateTime? customDate;
  final void Function(DateTime?)? onDateSelected;

  static String _formatLabel(String option) {
    switch (option) {
      case 'day':
        return 'Day';
      case 'week':
        return 'Week';
      case 'month':
        return 'Month';
      default:
        return option;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((option) {
        final isSelected = option == selected && customDate == null;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isSelected ? CupertinoColors.activeBlue : null,
            onPressed: () {
              onDateSelected?.call(null);
              onChanged(option);
            },
            child: Text(_formatLabel(option)),
          ),
        );
      }).toList(),
    );
  }
}

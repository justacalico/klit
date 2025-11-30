import 'package:flutter/cupertino.dart';

/// Time range selector for hot/popular pages
class TimeRangeSelector extends StatelessWidget {
  final String selected;
  final List<String> options;
  final Function(String) onChanged;

  const TimeRangeSelector({
    super.key,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: options.map((option) {
          final isSelected = option == selected;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? CupertinoTheme.of(context).primaryColor
                      : CupertinoColors.systemGrey5.resolveFrom(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatLabel(option),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? CupertinoColors.white
                        : CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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

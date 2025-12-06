import 'dart:ui';
import 'package:flutter/cupertino.dart';

/// Time range selector for hot/popular pages with iOS 26 liquid glass style
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
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    
    return Container(
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
              children: options.map((option) {
                final isSelected = option == selected;
                return GestureDetector(
                  onTap: () => onChanged(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              }).toList(),
            ),
          ),
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

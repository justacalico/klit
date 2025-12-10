import 'dart:ui';
import 'package:flutter/cupertino.dart';

/// Design constants for the purple/indigo theme
class DesktopToolbarColors {
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
}

/// Modern glassmorphic toolbar for desktop pages
class DesktopToolbar extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget>? actions;
  final Widget? leading;

  const DesktopToolbar({
    super.key,
    required this.title,
    required this.icon,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF18181B).withValues(alpha: 0.85),
                      const Color(0xFF1F1F23).withValues(alpha: 0.9),
                    ]
                  : [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.85),
                      const Color(0xFFFAFAFC).withValues(alpha: 0.9),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? DesktopToolbarColors.primaryPurple.withValues(alpha: 0.15)
                    : DesktopToolbarColors.primaryPurple.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 14),
              ] else ...[
                // Page icon with gradient
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        DesktopToolbarColors.primaryIndigo,
                        DesktopToolbarColors.primaryPurple,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: DesktopToolbarColors.primaryPurple.withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: CupertinoColors.white,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color:
                      isDark ? CupertinoColors.white : const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Styled toolbar button with hover effect
class DesktopToolbarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const DesktopToolbarButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  State<DesktopToolbarButton> createState() => _DesktopToolbarButtonState();
}

class _DesktopToolbarButtonState extends State<DesktopToolbarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: _isHovered
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DesktopToolbarColors.primaryIndigo.withValues(alpha: 0.15),
                      DesktopToolbarColors.primaryPurple.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            color: _isHovered
                ? null
                : isDark
                    ? const Color(0xFF2C2C2E).withValues(alpha: 0.6)
                    : const Color(0xFFF3F4F6).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? DesktopToolbarColors.primaryPurple.withValues(alpha: 0.3)
                  : isDark
                      ? const Color(0xFF3A3A3C).withValues(alpha: 0.3)
                      : const Color(0xFFE5E7EB).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _isHovered
                ? DesktopToolbarColors.primaryPurple
                : isDark
                    ? CupertinoColors.white
                    : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}

/// Grid size selector for posts grid
class DesktopGridSizeSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final List<int> options;

  const DesktopGridSizeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.options = const [2, 3, 4, 5, 6],
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.square_grid_2x2,
          size: 16,
          color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey,
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF3A3A3C).withValues(alpha: 0.3)
                  : const Color(0xFFE5E7EB).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: CupertinoSlidingSegmentedControl<int>(
            groupValue: value,
            backgroundColor: isDark
                ? const Color(0xFF2C2C2E).withValues(alpha: 0.5)
                : const Color(0xFFF3F4F6).withValues(alpha: 0.8),
            thumbColor: isDark
                ? const Color(0xFF3A3A3C)
                : CupertinoColors.white,
            children: {
              for (final opt in options)
                opt: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '$opt',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? CupertinoColors.white
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
            },
            onValueChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
      ],
    );
  }
}

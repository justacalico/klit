import 'package:flutter/cupertino.dart';

import '../theme.dart';

/// Page toolbar for desktop content area.
class PageToolbar extends StatelessWidget {
  const PageToolbar({
    super.key,
    required this.title,
    required this.icon,
    this.actions,
    this.leading,
  });

  final String title;
  final IconData icon;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    final content = Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFFAFAFC),
        border: Border(
          bottom: BorderSide(
            color: UIColors.primaryPurple.withValues(alpha: isDark ? 0.15 : 0.1),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [UIColors.primaryIndigo, UIColors.primaryPurple],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: CupertinoColors.white),
            ),
            const SizedBox(width: 14),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );

    return content;
  }
}

/// Toolbar action button
class ToolbarButton extends StatefulWidget {
  const ToolbarButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  State<ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<ToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final disabled = widget.onPressed == null;

    return MouseRegion(
      onEnter: disabled ? null : (_) => setState(() => _hovered = true),
      onExit: disabled ? null : (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hovered && !disabled
                ? UIColors.primaryPurple.withValues(alpha: 0.15)
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered && !disabled
                  ? UIColors.primaryPurple.withValues(alpha: 0.3)
                  : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB)),
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: disabled
                ? CupertinoColors.systemGrey
                : (_hovered ? UIColors.primaryPurple : (isDark ? CupertinoColors.white : const Color(0xFF374151))),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'gamepad_controller.dart';

/// Configuration for gamepad navigation behavior
class GamepadNavigationConfig {
  /// Enable/disable gamepad navigation
  final bool enabled;

  /// Show visual focus indicators
  final bool showFocusIndicator;

  /// Color for focus indicator
  final Color focusColor;

  /// Border radius for focus indicator
  final double focusBorderRadius;

  /// Focus indicator border width
  final double focusBorderWidth;

  /// Haptic feedback on navigation
  final bool hapticFeedback;

  const GamepadNavigationConfig({
    this.enabled = true,
    this.showFocusIndicator = true,
    this.focusColor = const Color(0xFF6366F1),
    this.focusBorderRadius = 12.0,
    this.focusBorderWidth = 3.0,
    this.hapticFeedback = true,
  });
}

/// Provider for gamepad navigation state
class GamepadNavigationProvider extends InheritedWidget {
  final GamepadNavigationState state;

  const GamepadNavigationProvider({
    super.key,
    required this.state,
    required super.child,
  });

  static GamepadNavigationState? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GamepadNavigationProvider>()
        ?.state;
  }

  @override
  bool updateShouldNotify(GamepadNavigationProvider oldWidget) {
    return state != oldWidget.state;
  }
}

/// State manager for gamepad navigation
class GamepadNavigationState extends ChangeNotifier {
  final GamepadNavigationConfig config;

  // Focus management
  int _focusedIndex = 0;
  int _gridColumns = 4;
  int _itemCount = 0;
  bool _isNavigating = false;

  // Scroll controller for auto-scrolling to focused item
  ScrollController? _scrollController;
  double _itemHeight = 200.0;
  double _itemSpacing = 8.0;

  GamepadNavigationState({this.config = const GamepadNavigationConfig()});

  int get focusedIndex => _focusedIndex;
  bool get isNavigating => _isNavigating;

  void setGridLayout({
    required int columns,
    required int itemCount,
    double itemHeight = 200.0,
    double itemSpacing = 8.0,
  }) {
    _gridColumns = columns;
    _itemCount = itemCount;
    _itemHeight = itemHeight;
    _itemSpacing = itemSpacing;

    // Clamp focused index to valid range
    if (_focusedIndex >= itemCount && itemCount > 0) {
      _focusedIndex = itemCount - 1;
      notifyListeners();
    }
  }

  void attachScrollController(ScrollController controller) {
    _scrollController = controller;
  }

  void detachScrollController() {
    _scrollController = null;
  }

  /// Navigate in a direction
  void navigate(GamepadDirection direction) {
    if (_itemCount == 0) return;

    _isNavigating = true;
    final oldIndex = _focusedIndex;

    switch (direction) {
      case GamepadDirection.up:
        if (_focusedIndex >= _gridColumns) {
          _focusedIndex -= _gridColumns;
        }
      case GamepadDirection.down:
        if (_focusedIndex + _gridColumns < _itemCount) {
          _focusedIndex += _gridColumns;
        } else if (_focusedIndex < _itemCount - 1) {
          // Move to last item if not already there
          _focusedIndex = _itemCount - 1;
        }
      case GamepadDirection.left:
        if (_focusedIndex > 0) {
          _focusedIndex--;
        }
      case GamepadDirection.right:
        if (_focusedIndex < _itemCount - 1) {
          _focusedIndex++;
        }
    }

    if (oldIndex != _focusedIndex) {
      _scrollToFocusedItem();
      if (config.hapticFeedback) {
        HapticFeedback.selectionClick();
      }
      notifyListeners();
    }
  }

  /// Set focus to a specific index
  void setFocusedIndex(int index) {
    if (index >= 0 && index < _itemCount && index != _focusedIndex) {
      _focusedIndex = index;
      _isNavigating = false;
      notifyListeners();
    }
  }

  /// Reset navigation mode (e.g., when using touch/mouse)
  void resetNavigating() {
    if (_isNavigating) {
      _isNavigating = false;
      notifyListeners();
    }
  }

  void _scrollToFocusedItem() {
    if (_scrollController == null || !_scrollController!.hasClients) return;

    final row = _focusedIndex ~/ _gridColumns;
    final targetOffset = row * (_itemHeight + _itemSpacing);
    final viewportHeight = _scrollController!.position.viewportDimension;
    final currentOffset = _scrollController!.offset;

    // Scroll only if item is outside visible area
    if (targetOffset < currentOffset) {
      _scrollController!.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    } else if (targetOffset + _itemHeight > currentOffset + viewportHeight) {
      _scrollController!.animateTo(
        targetOffset + _itemHeight - viewportHeight + _itemSpacing,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Get the currently focused item index
  int? getConfirmIndex() {
    if (_isNavigating && _focusedIndex >= 0 && _focusedIndex < _itemCount) {
      return _focusedIndex;
    }
    return null;
  }
}

/// Widget that enables gamepad navigation for its child
class GamepadNavigator extends StatefulWidget {
  final Widget child;
  final GamepadNavigationConfig config;
  final GamepadNavigationState? externalState;
  final void Function(int index)? onSelect;
  final VoidCallback? onBack;

  const GamepadNavigator({
    super.key,
    required this.child,
    this.config = const GamepadNavigationConfig(),
    this.externalState,
    this.onSelect,
    this.onBack,
  });

  @override
  State<GamepadNavigator> createState() => _GamepadNavigatorState();
}

class _GamepadNavigatorState extends State<GamepadNavigator>
    with GamepadInputMixin {
  late GamepadNavigationState _state;

  @override
  void initState() {
    super.initState();
    _state =
        widget.externalState ?? GamepadNavigationState(config: widget.config);

    // Ensure gamepad controller is initialized
    GamepadController().initialize();
  }

  @override
  void dispose() {
    if (widget.externalState == null) {
      _state.dispose();
    }
    super.dispose();
  }

  @override
  void onGamepadDirection(GamepadDirection direction) {
    if (!widget.config.enabled) return;
    _state.navigate(direction);
  }

  @override
  void onGamepadButton(GamepadButton button) {
    if (!widget.config.enabled) return;

    switch (button) {
      case GamepadButton.a:
        // Confirm/select
        final index = _state.getConfirmIndex();
        if (index != null && widget.onSelect != null) {
          HapticFeedback.mediumImpact();
          widget.onSelect!(index);
        }
      case GamepadButton.b:
        // Back/cancel
        if (widget.onBack != null) {
          HapticFeedback.lightImpact();
          widget.onBack!();
        }
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GamepadNavigationProvider(state: _state, child: widget.child);
  }
}

/// Focus indicator widget for grid items
class GamepadFocusIndicator extends StatelessWidget {
  final bool isFocused;
  final Widget child;
  final GamepadNavigationConfig config;

  const GamepadFocusIndicator({
    super.key,
    required this.isFocused,
    required this.child,
    this.config = const GamepadNavigationConfig(),
  });

  @override
  Widget build(BuildContext context) {
    if (!config.showFocusIndicator || !isFocused) {
      return child;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(config.focusBorderRadius),
        border: Border.all(
          color: config.focusColor,
          width: config.focusBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: config.focusColor.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          config.focusBorderRadius - config.focusBorderWidth,
        ),
        child: child,
      ),
    );
  }
}

/// Widget that wraps a grid item with gamepad focus support
class GamepadFocusableItem extends StatelessWidget {
  final int index;
  final Widget child;
  final VoidCallback? onTap;

  const GamepadFocusableItem({
    super.key,
    required this.index,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navState = GamepadNavigationProvider.of(context);

    if (navState == null) {
      return GestureDetector(onTap: onTap, child: child);
    }

    return ListenableBuilder(
      listenable: navState,
      builder: (context, _) {
        final isFocused =
            navState.isNavigating && navState.focusedIndex == index;

        return GestureDetector(
          onTap: () {
            navState.setFocusedIndex(index);
            navState.resetNavigating();
            onTap?.call();
          },
          child: GamepadFocusIndicator(
            isFocused: isFocused,
            config: navState.config,
            child: child,
          ),
        );
      },
    );
  }
}

/// Controller actions widget for displaying button hints
class GamepadButtonHints extends StatelessWidget {
  final List<GamepadButtonHint> hints;
  final bool show;

  const GamepadButtonHints({super.key, required this.hints, this.show = true});

  @override
  Widget build(BuildContext context) {
    if (!show || hints.isEmpty) return const SizedBox.shrink();

    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: hints.map((hint) => _buildHint(hint, isDark)).toList(),
    );
  }

  Widget _buildHint(GamepadButtonHint hint, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8),
            ),
          ),
          child: Text(
            hint.button.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          hint.label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF71717A) : const Color(0xFF71717A),
          ),
        ),
      ],
    );
  }
}

/// A single button hint
class GamepadButtonHint {
  final GamepadButton button;
  final String label;

  const GamepadButtonHint({required this.button, required this.label});
}

/// Extension to get display name for buttons
extension GamepadButtonDisplayName on GamepadButton {
  String get displayName {
    switch (this) {
      case GamepadButton.a:
        return 'A';
      case GamepadButton.b:
        return 'B';
      case GamepadButton.x:
        return 'X';
      case GamepadButton.y:
        return 'Y';
      case GamepadButton.leftBumper:
        return 'LB';
      case GamepadButton.rightBumper:
        return 'RB';
      case GamepadButton.leftTrigger:
        return 'LT';
      case GamepadButton.rightTrigger:
        return 'RT';
      case GamepadButton.leftStick:
        return 'L3';
      case GamepadButton.rightStick:
        return 'R3';
      case GamepadButton.dpadUp:
        return '↑';
      case GamepadButton.dpadDown:
        return '↓';
      case GamepadButton.dpadLeft:
        return '←';
      case GamepadButton.dpadRight:
        return '→';
      case GamepadButton.start:
        return '☰';
      case GamepadButton.select:
        return '⊞';
      case GamepadButton.guide:
        return '⊕';
    }
  }
}

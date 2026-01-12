import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Gamepad button identifiers for cross-platform compatibility
/// Supports Xbox, PlayStation, and Steam Deck controllers
enum GamepadButton {
  // Face buttons
  a, // A (Xbox) / Cross (PS) / A (Nintendo)
  b, // B (Xbox) / Circle (PS) / B (Nintendo)
  x, // X (Xbox) / Square (PS) / Y (Nintendo)
  y, // Y (Xbox) / Triangle (PS) / X (Nintendo)
  // Bumpers and triggers
  leftBumper, // LB / L1
  rightBumper, // RB / R1
  leftTrigger, // LT / L2
  rightTrigger, // RT / R2
  // Stick buttons
  leftStick, // L3
  rightStick, // R3
  // D-Pad
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,

  // Menu buttons
  start, // Start / Options / Menu
  select, // Select / Share / View
  // Special
  guide, // Xbox button / PS button / Home
}

/// Thumbstick axis values
class ThumbstickState {
  final double x; // -1.0 to 1.0 (left to right)
  final double y; // -1.0 to 1.0 (up to down, inverted on some controllers)

  const ThumbstickState({this.x = 0.0, this.y = 0.0});

  /// Dead zone threshold - ignore small movements
  static const double deadZone = 0.15;

  /// Returns true if the stick is moved beyond the dead zone
  bool get isActive => x.abs() > deadZone || y.abs() > deadZone;

  /// Normalized direction, accounting for dead zone
  ThumbstickState get normalized {
    if (!isActive) return const ThumbstickState();
    return ThumbstickState(
      x: x.abs() > deadZone ? x : 0.0,
      y: y.abs() > deadZone ? y : 0.0,
    );
  }

  /// Get the dominant direction (for menu navigation)
  GamepadDirection? get direction {
    if (!isActive) return null;
    final absX = x.abs();
    final absY = y.abs();

    // Require a threshold for clear direction
    const threshold = 0.5;

    if (absY > absX && absY > threshold) {
      return y < 0 ? GamepadDirection.up : GamepadDirection.down;
    } else if (absX > absY && absX > threshold) {
      return x < 0 ? GamepadDirection.left : GamepadDirection.right;
    }
    return null;
  }

  @override
  String toString() =>
      'ThumbstickState(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)})';
}

/// Navigation directions for thumbstick
enum GamepadDirection { up, down, left, right }

/// Complete gamepad state snapshot
class GamepadState {
  final Set<GamepadButton> pressedButtons;
  final ThumbstickState leftStick;
  final ThumbstickState rightStick;
  final double leftTrigger; // 0.0 to 1.0
  final double rightTrigger; // 0.0 to 1.0
  final bool isConnected;

  const GamepadState({
    this.pressedButtons = const {},
    this.leftStick = const ThumbstickState(),
    this.rightStick = const ThumbstickState(),
    this.leftTrigger = 0.0,
    this.rightTrigger = 0.0,
    this.isConnected = false,
  });

  bool isPressed(GamepadButton button) => pressedButtons.contains(button);

  GamepadState copyWith({
    Set<GamepadButton>? pressedButtons,
    ThumbstickState? leftStick,
    ThumbstickState? rightStick,
    double? leftTrigger,
    double? rightTrigger,
    bool? isConnected,
  }) {
    return GamepadState(
      pressedButtons: pressedButtons ?? this.pressedButtons,
      leftStick: leftStick ?? this.leftStick,
      rightStick: rightStick ?? this.rightStick,
      leftTrigger: leftTrigger ?? this.leftTrigger,
      rightTrigger: rightTrigger ?? this.rightTrigger,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

/// Gamepad event types
enum GamepadEventType {
  buttonDown,
  buttonUp,
  thumbstickMove,
  triggerChange,
  connected,
  disconnected,
}

/// Gamepad event
class GamepadEvent {
  final GamepadEventType type;
  final GamepadButton? button;
  final ThumbstickState? thumbstick;
  final bool isLeftStick;
  final double? triggerValue;
  final bool isLeftTrigger;
  final DateTime timestamp;

  GamepadEvent({
    required this.type,
    this.button,
    this.thumbstick,
    this.isLeftStick = true,
    this.triggerValue,
    this.isLeftTrigger = true,
  }) : timestamp = DateTime.now();
}

/// Singleton service for handling gamepad input
/// Supports Xbox, PlayStation, Steam Deck, and generic HID controllers
class GamepadController {
  static final GamepadController _instance = GamepadController._internal();
  factory GamepadController() => _instance;
  GamepadController._internal();

  // State
  GamepadState _state = const GamepadState();
  GamepadState get state => _state;

  // Event stream
  final _eventController = StreamController<GamepadEvent>.broadcast();
  Stream<GamepadEvent> get events => _eventController.stream;

  // State change stream
  final _stateController = StreamController<GamepadState>.broadcast();
  Stream<GamepadState> get stateChanges => _stateController.stream;

  // Button press stream (debounced for menu navigation)
  final _buttonPressController = StreamController<GamepadButton>.broadcast();
  Stream<GamepadButton> get buttonPresses => _buttonPressController.stream;

  // Direction stream for navigation (debounced)
  final _directionController = StreamController<GamepadDirection>.broadcast();
  Stream<GamepadDirection> get directions => _directionController.stream;

  // Previous button states for detecting edges
  final Set<GamepadButton> _previousButtons = {};
  GamepadDirection? _lastDirection;
  DateTime? _lastDirectionTime;

  // Navigation repeat timing
  static const Duration _initialRepeatDelay = Duration(milliseconds: 400);
  static const Duration _repeatInterval = Duration(milliseconds: 150);
  Timer? _repeatTimer;
  GamepadDirection? _repeatDirection;

  // Polling
  Timer? _pollTimer;
  bool _isInitialized = false;
  static const Duration _pollInterval = Duration(milliseconds: 16); // ~60fps

  /// Initialize the gamepad controller
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Start polling for gamepad state
    _startPolling();

    // Also listen to raw keyboard events for keyboard-based gamepad simulation
    // (useful for testing without a controller)
    HardwareKeyboard.instance.addHandler(_handleKeyboardEvent);

    debugPrint('[GamepadController] Initialized');
  }

  /// Dispose of resources
  void dispose() {
    _pollTimer?.cancel();
    _repeatTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyboardEvent);
    _eventController.close();
    _stateController.close();
    _buttonPressController.close();
    _directionController.close();
    _isInitialized = false;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollGamepad());
  }

  void _pollGamepad() {
    // Query gamepad state using Flutter's GamepadAPI
    // This uses the low-level HID interface
    _queryGamepadState();
  }

  void _queryGamepadState() {
    // Flutter doesn't have a direct gamepad API yet, so we rely on
    // key events mapped to gamepad buttons through SDL/Steam Input
    // The actual gamepad polling is done through platform channels
    // or the RawKeyboardListener for mapped keys

    // For SteamOS/Steam Deck, Steam Input maps controller buttons to keyboard keys
    // We handle this through the keyboard event handler below

    // Process thumbstick navigation repeat
    _processNavigationRepeat();
  }

  void _processNavigationRepeat() {
    if (_repeatDirection == null || _lastDirectionTime == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(_lastDirectionTime!);

    // Check if we should repeat
    if (_repeatTimer == null && elapsed >= _initialRepeatDelay) {
      _repeatTimer = Timer.periodic(_repeatInterval, (_) {
        if (_repeatDirection != null &&
            _state.leftStick.direction == _repeatDirection) {
          _directionController.add(_repeatDirection!);
          _lastDirectionTime = DateTime.now();
        } else {
          _repeatTimer?.cancel();
          _repeatTimer = null;
          _repeatDirection = null;
        }
      });
    }
  }

  /// Handle keyboard events (including gamepad buttons mapped via Steam Input)
  bool _handleKeyboardEvent(KeyEvent event) {
    final button = _mapKeyToButton(event.logicalKey);

    if (button != null) {
      if (event is KeyDownEvent) {
        // Check if this is a repeat event by seeing if button was already down
        if (!_state.pressedButtons.contains(button)) {
          _handleButtonDown(button);
        }
        return true;
      } else if (event is KeyUpEvent) {
        _handleButtonUp(button);
        return true;
      }
    }

    // Handle arrow keys as D-pad (for testing and some Steam Input configs)
    final direction = _mapKeyToDirection(event.logicalKey);
    if (direction != null) {
      if (event is KeyDownEvent) {
        // Only handle if not already repeating this direction
        if (_repeatDirection != direction) {
          _handleDirectionInput(direction);
        }
        return true;
      } else if (event is KeyUpEvent) {
        _handleDirectionRelease(direction);
        return true;
      }
    }

    return false;
  }

  /// Map logical key to gamepad button
  /// Steam Input can map controller buttons to various keys
  GamepadButton? _mapKeyToButton(LogicalKeyboardKey key) {
    // Xbox controller button mappings (common Steam Input defaults)
    switch (key) {
      // Face buttons - using common game mappings
      case LogicalKeyboardKey.space: // A button (confirm)
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.gameButtonA:
        return GamepadButton.a;

      case LogicalKeyboardKey.escape: // B button (back/cancel)
      case LogicalKeyboardKey.backspace:
      case LogicalKeyboardKey.gameButtonB:
        return GamepadButton.b;

      case LogicalKeyboardKey.keyX: // X button (action)
      case LogicalKeyboardKey.gameButtonX:
        return GamepadButton.x;

      case LogicalKeyboardKey.keyY: // Y button (secondary action)
      case LogicalKeyboardKey.gameButtonY:
        return GamepadButton.y;

      // Bumpers
      case LogicalKeyboardKey.keyQ: // Left bumper
      case LogicalKeyboardKey.pageUp:
      case LogicalKeyboardKey.gameButtonLeft1:
        return GamepadButton.leftBumper;

      case LogicalKeyboardKey.keyE: // Right bumper
      case LogicalKeyboardKey.pageDown:
      case LogicalKeyboardKey.gameButtonRight1:
        return GamepadButton.rightBumper;

      // Triggers (as buttons)
      case LogicalKeyboardKey.keyZ: // Left trigger
      case LogicalKeyboardKey.gameButtonLeft2:
        return GamepadButton.leftTrigger;

      case LogicalKeyboardKey.keyC: // Right trigger
      case LogicalKeyboardKey.gameButtonRight2:
        return GamepadButton.rightTrigger;

      // Menu buttons
      case LogicalKeyboardKey.f10: // Start/Menu
      case LogicalKeyboardKey.gameButtonStart:
        return GamepadButton.start;

      case LogicalKeyboardKey.f9: // Select/View
      case LogicalKeyboardKey.gameButtonSelect:
        return GamepadButton.select;

      // D-Pad (as buttons when not using direction handler)
      case LogicalKeyboardKey.gameButtonThumbLeft:
        return GamepadButton.leftStick;

      case LogicalKeyboardKey.gameButtonThumbRight:
        return GamepadButton.rightStick;

      default:
        return null;
    }
  }

  /// Map arrow/WASD keys to directions
  GamepadDirection? _mapKeyToDirection(LogicalKeyboardKey key) {
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        return GamepadDirection.up;

      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        return GamepadDirection.down;

      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        return GamepadDirection.left;

      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        return GamepadDirection.right;

      default:
        return null;
    }
  }

  void _handleButtonDown(GamepadButton button) {
    if (_previousButtons.contains(button)) return;

    _previousButtons.add(button);
    final newState = _state.copyWith(
      pressedButtons: {..._state.pressedButtons, button},
      isConnected: true,
    );
    _updateState(newState);

    _eventController.add(
      GamepadEvent(type: GamepadEventType.buttonDown, button: button),
    );

    _buttonPressController.add(button);

    debugPrint('[GamepadController] Button down: $button');
  }

  void _handleButtonUp(GamepadButton button) {
    if (!_previousButtons.contains(button)) return;

    _previousButtons.remove(button);
    final newButtons = Set<GamepadButton>.from(_state.pressedButtons)
      ..remove(button);
    final newState = _state.copyWith(pressedButtons: newButtons);
    _updateState(newState);

    _eventController.add(
      GamepadEvent(type: GamepadEventType.buttonUp, button: button),
    );
  }

  void _handleDirectionInput(GamepadDirection direction) {
    // Emit direction immediately on first press
    _directionController.add(direction);
    _lastDirection = direction;
    _lastDirectionTime = DateTime.now();
    _repeatDirection = direction;

    // Update thumbstick state
    final stick = ThumbstickState(
      x: direction == GamepadDirection.left
          ? -1.0
          : (direction == GamepadDirection.right ? 1.0 : 0.0),
      y: direction == GamepadDirection.up
          ? -1.0
          : (direction == GamepadDirection.down ? 1.0 : 0.0),
    );
    final newState = _state.copyWith(leftStick: stick, isConnected: true);
    _updateState(newState);

    debugPrint('[GamepadController] Direction: $direction');
  }

  void _handleDirectionRelease(GamepadDirection direction) {
    if (_lastDirection == direction) {
      _repeatTimer?.cancel();
      _repeatTimer = null;
      _repeatDirection = null;
      _lastDirection = null;

      final newState = _state.copyWith(leftStick: const ThumbstickState());
      _updateState(newState);
    }
  }

  /// Update thumbstick state (called from native platform channel)
  void updateThumbstick({
    required bool isLeft,
    required double x,
    required double y,
  }) {
    final stick = ThumbstickState(x: x, y: y);
    final newState = isLeft
        ? _state.copyWith(leftStick: stick, isConnected: true)
        : _state.copyWith(rightStick: stick, isConnected: true);
    _updateState(newState);

    _eventController.add(
      GamepadEvent(
        type: GamepadEventType.thumbstickMove,
        thumbstick: stick,
        isLeftStick: isLeft,
      ),
    );

    // Handle navigation from thumbstick
    if (isLeft) {
      final direction = stick.normalized.direction;
      if (direction != null && direction != _lastDirection) {
        _handleDirectionInput(direction);
      } else if (direction == null && _lastDirection != null) {
        _handleDirectionRelease(_lastDirection!);
      }
    }
  }

  /// Update trigger value (called from native platform channel)
  void updateTrigger({required bool isLeft, required double value}) {
    final newState = isLeft
        ? _state.copyWith(leftTrigger: value, isConnected: true)
        : _state.copyWith(rightTrigger: value, isConnected: true);
    _updateState(newState);

    _eventController.add(
      GamepadEvent(
        type: GamepadEventType.triggerChange,
        triggerValue: value,
        isLeftTrigger: isLeft,
      ),
    );

    // Treat trigger as button when crossing threshold
    const threshold = 0.5;
    final button = isLeft
        ? GamepadButton.leftTrigger
        : GamepadButton.rightTrigger;
    final wasPressed = _previousButtons.contains(button);
    final isPressed = value >= threshold;

    if (isPressed && !wasPressed) {
      _handleButtonDown(button);
    } else if (!isPressed && wasPressed) {
      _handleButtonUp(button);
    }
  }

  void _updateState(GamepadState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  /// Simulate a button press (for testing)
  void simulateButtonPress(GamepadButton button) {
    _handleButtonDown(button);
    Future.delayed(const Duration(milliseconds: 100), () {
      _handleButtonUp(button);
    });
  }

  /// Simulate direction input (for testing)
  void simulateDirection(GamepadDirection direction) {
    _handleDirectionInput(direction);
    Future.delayed(const Duration(milliseconds: 100), () {
      _handleDirectionRelease(direction);
    });
  }

  /// Check if controller is available
  bool get isConnected => _state.isConnected;
}

/// Mixin for widgets that need controller input
mixin GamepadInputMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<GamepadButton>? _buttonSubscription;
  StreamSubscription<GamepadDirection>? _directionSubscription;

  GamepadController get gamepad => GamepadController();

  @override
  void initState() {
    super.initState();
    _buttonSubscription = gamepad.buttonPresses.listen(onGamepadButton);
    _directionSubscription = gamepad.directions.listen(onGamepadDirection);
  }

  @override
  void dispose() {
    _buttonSubscription?.cancel();
    _directionSubscription?.cancel();
    super.dispose();
  }

  /// Override to handle button presses
  void onGamepadButton(GamepadButton button) {}

  /// Override to handle direction input
  void onGamepadDirection(GamepadDirection direction) {}
}

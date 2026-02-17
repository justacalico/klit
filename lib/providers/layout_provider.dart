import 'package:flutter/foundation.dart';

import '../ui/layout/layout_scope.dart';

/// Holds layout mode locked at first build. Resizing only updates view, never state.
/// Layout structure (desktop sidebar vs mobile nav) stays constant for the session.
class LayoutProvider extends ChangeNotifier {
  LayoutMode? _mode;

  LayoutMode get mode {
    assert(_mode != null, 'LayoutProvider.mode read before initialize()');
    return _mode!;
  }

  bool get isInitialized => _mode != null;

  /// Call once at app startup with initial viewport width. Mode is locked forever.
  void initialize(double width) {
    if (_mode != null) return;
    _mode = LayoutMode.fromWidth(width);
    notifyListeners();
  }

  bool get isDesktop => mode.isDesktop;
  bool get isMobile => mode.isMobile;
}

import 'package:flutter/services.dart';

/// Haptic feedback utility
class HapticUtils {
  HapticUtils._();

  /// Light impact feedback
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact feedback
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact feedback
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Selection click feedback
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate feedback
  static void vibrate() {
    HapticFeedback.vibrate();
  }
}

/// Validator utility for form validation
class Validators {
  Validators._();

  /// Validate that a field is not empty
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate API key format
  static String? apiKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'API key is required';
    }
    if (value.length < 24) {
      return 'API key is too short';
    }
    return null;
  }

  /// Validate username
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  /// Validate URL
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'URL is required';
    }
    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    if (!urlPattern.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }
}

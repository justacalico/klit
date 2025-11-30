/// Extension methods for num types
extension NumExtensions on num {
  /// Format number with K/M suffix
  String get compact {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    }
    return toString();
  }

  /// Format as file size
  String get fileSize {
    if (this >= 1073741824) {
      return '${(this / 1073741824).toStringAsFixed(2)} GB';
    } else if (this >= 1048576) {
      return '${(this / 1048576).toStringAsFixed(2)} MB';
    } else if (this >= 1024) {
      return '${(this / 1024).toStringAsFixed(2)} KB';
    }
    return '$this B';
  }
}

/// Extension methods for Duration
extension DurationExtensions on Duration {
  /// Format as mm:ss
  String get formatted {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    if (inHours > 0) {
      final hours = inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

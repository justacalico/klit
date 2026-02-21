/// A post marked as "I finished", with optional photo path.
class IFinishedEntry {
  const IFinishedEntry({required this.postId, this.imagePath});

  final int postId;
  final String? imagePath;

  Map<String, dynamic> toJson() => {
        'id': postId,
        if (imagePath != null) 'imagePath': imagePath,
      };

  static IFinishedEntry fromJson(Map<String, dynamic> json) {
    return IFinishedEntry(
      postId: (json['id'] as num).toInt(),
      imagePath: json['imagePath'] as String?,
    );
  }
}

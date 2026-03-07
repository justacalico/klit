class Finish {
  const Finish({
    required this.id,
    required this.identityId,
    required this.postId,
    required this.finishedAt,
    this.photoPath,
  });

  final int id;
  final int identityId;
  final int postId;
  final DateTime finishedAt;
  final String? photoPath;
}

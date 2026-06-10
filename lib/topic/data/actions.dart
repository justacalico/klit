import 'package:kilt/topic/topic.dart';

extension Link on Topic {
  String get link => '/forum_topics/$id';
}

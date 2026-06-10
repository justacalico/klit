import 'package:kilt/user/user.dart';

extension Linking on User {
  String get link => '/users/$name';
}

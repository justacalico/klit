import 'package:klit/user/user.dart';

extension Linking on User {
  String get link => '/users/$name';
}

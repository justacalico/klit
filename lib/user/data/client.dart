import 'package:dio/dio.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/user/user.dart';

class UserClient {
  UserClient({required this.dio});

  final Dio dio;

  // Technically missing users()
  Future<User> get({
    required String id,
    bool? force,
    CancelToken? cancelToken,
  }) => dio
      .get(
        '/users/$id.json',
        options: forceOptions(force),
        cancelToken: cancelToken,
      )
      .then((response) => E621User.fromJson(response.data));
}

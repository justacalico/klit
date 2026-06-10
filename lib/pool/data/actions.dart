import 'package:kilt/pool/pool.dart';

extension Linking on Pool {
  String get link => getPoolLink(id);
}

String getPoolLink(int id) => '/pools/$id';

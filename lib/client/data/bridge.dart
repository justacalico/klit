import 'package:kilt/shared/shared.dart';
import 'package:kilt/traits/traits.dart';

abstract class BridgeClient {
  Future<void> available();

  Future<void> push({required Traits traits, CancelToken? cancelToken});

  Future<void> pull({bool? force, CancelToken? cancelToken});
}

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClientSyncStatus {

 DenyListSyncStatus? get denyList;
/// Create a copy of ClientSyncStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClientSyncStatusCopyWith<ClientSyncStatus> get copyWith => _$ClientSyncStatusCopyWithImpl<ClientSyncStatus>(this as ClientSyncStatus, _$identity);

  /// Serializes this ClientSyncStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClientSyncStatus&&(identical(other.denyList, denyList) || other.denyList == denyList));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,denyList);

@override
String toString() {
  return 'ClientSyncStatus(denyList: $denyList)';
}


}

/// @nodoc
abstract mixin class $ClientSyncStatusCopyWith<$Res>  {
  factory $ClientSyncStatusCopyWith(ClientSyncStatus value, $Res Function(ClientSyncStatus) _then) = _$ClientSyncStatusCopyWithImpl;
@useResult
$Res call({
 DenyListSyncStatus? denyList
});




}
/// @nodoc
class _$ClientSyncStatusCopyWithImpl<$Res>
    implements $ClientSyncStatusCopyWith<$Res> {
  _$ClientSyncStatusCopyWithImpl(this._self, this._then);

  final ClientSyncStatus _self;
  final $Res Function(ClientSyncStatus) _then;

/// Create a copy of ClientSyncStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? denyList = freezed,}) {
  return _then(_self.copyWith(
denyList: freezed == denyList ? _self.denyList : denyList // ignore: cast_nullable_to_non_nullable
as DenyListSyncStatus?,
  ));
}

}


/// Adds pattern-matching-related methods to [ClientSyncStatus].
extension ClientSyncStatusPatterns on ClientSyncStatus {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClientSyncStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClientSyncStatus() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClientSyncStatus value)  $default,){
final _that = this;
switch (_that) {
case _ClientSyncStatus():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClientSyncStatus value)?  $default,){
final _that = this;
switch (_that) {
case _ClientSyncStatus() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DenyListSyncStatus? denyList)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClientSyncStatus() when $default != null:
return $default(_that.denyList);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DenyListSyncStatus? denyList)  $default,) {final _that = this;
switch (_that) {
case _ClientSyncStatus():
return $default(_that.denyList);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DenyListSyncStatus? denyList)?  $default,) {final _that = this;
switch (_that) {
case _ClientSyncStatus() when $default != null:
return $default(_that.denyList);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClientSyncStatus implements ClientSyncStatus {
  const _ClientSyncStatus({this.denyList});
  factory _ClientSyncStatus.fromJson(Map<String, dynamic> json) => _$ClientSyncStatusFromJson(json);

@override final  DenyListSyncStatus? denyList;

/// Create a copy of ClientSyncStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClientSyncStatusCopyWith<_ClientSyncStatus> get copyWith => __$ClientSyncStatusCopyWithImpl<_ClientSyncStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClientSyncStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClientSyncStatus&&(identical(other.denyList, denyList) || other.denyList == denyList));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,denyList);

@override
String toString() {
  return 'ClientSyncStatus(denyList: $denyList)';
}


}

/// @nodoc
abstract mixin class _$ClientSyncStatusCopyWith<$Res> implements $ClientSyncStatusCopyWith<$Res> {
  factory _$ClientSyncStatusCopyWith(_ClientSyncStatus value, $Res Function(_ClientSyncStatus) _then) = __$ClientSyncStatusCopyWithImpl;
@override @useResult
$Res call({
 DenyListSyncStatus? denyList
});




}
/// @nodoc
class __$ClientSyncStatusCopyWithImpl<$Res>
    implements _$ClientSyncStatusCopyWith<$Res> {
  __$ClientSyncStatusCopyWithImpl(this._self, this._then);

  final _ClientSyncStatus _self;
  final $Res Function(_ClientSyncStatus) _then;

/// Create a copy of ClientSyncStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? denyList = freezed,}) {
  return _then(_ClientSyncStatus(
denyList: freezed == denyList ? _self.denyList : denyList // ignore: cast_nullable_to_non_nullable
as DenyListSyncStatus?,
  ));
}


}

// dart format on

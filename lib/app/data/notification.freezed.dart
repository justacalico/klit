// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationPayload {

 int get identity; String get type; Map<String, String>? get query; int? get id;
/// Create a copy of NotificationPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPayloadCopyWith<NotificationPayload> get copyWith => _$NotificationPayloadCopyWithImpl<NotificationPayload>(this as NotificationPayload, _$identity);

  /// Serializes this NotificationPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPayload&&(identical(other.identity, identity) || other.identity == identity)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.query, query)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,identity,type,const DeepCollectionEquality().hash(query),id);

@override
String toString() {
  return 'NotificationPayload(identity: $identity, type: $type, query: $query, id: $id)';
}


}

/// @nodoc
abstract mixin class $NotificationPayloadCopyWith<$Res>  {
  factory $NotificationPayloadCopyWith(NotificationPayload value, $Res Function(NotificationPayload) _then) = _$NotificationPayloadCopyWithImpl;
@useResult
$Res call({
 int identity, String type, Map<String, String>? query, int? id
});




}
/// @nodoc
class _$NotificationPayloadCopyWithImpl<$Res>
    implements $NotificationPayloadCopyWith<$Res> {
  _$NotificationPayloadCopyWithImpl(this._self, this._then);

  final NotificationPayload _self;
  final $Res Function(NotificationPayload) _then;

/// Create a copy of NotificationPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? identity = null,Object? type = null,Object? query = freezed,Object? id = freezed,}) {
  return _then(_self.copyWith(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPayload].
extension NotificationPayloadPatterns on NotificationPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPayload value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPayload value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int identity,  String type,  Map<String, String>? query,  int? id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPayload() when $default != null:
return $default(_that.identity,_that.type,_that.query,_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int identity,  String type,  Map<String, String>? query,  int? id)  $default,) {final _that = this;
switch (_that) {
case _NotificationPayload():
return $default(_that.identity,_that.type,_that.query,_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int identity,  String type,  Map<String, String>? query,  int? id)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPayload() when $default != null:
return $default(_that.identity,_that.type,_that.query,_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationPayload implements NotificationPayload {
  const _NotificationPayload({required this.identity, required this.type, final  Map<String, String>? query, this.id}): _query = query;
  factory _NotificationPayload.fromJson(Map<String, dynamic> json) => _$NotificationPayloadFromJson(json);

@override final  int identity;
@override final  String type;
 final  Map<String, String>? _query;
@override Map<String, String>? get query {
  final value = _query;
  if (value == null) return null;
  if (_query is EqualUnmodifiableMapView) return _query;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  int? id;

/// Create a copy of NotificationPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPayloadCopyWith<_NotificationPayload> get copyWith => __$NotificationPayloadCopyWithImpl<_NotificationPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPayload&&(identical(other.identity, identity) || other.identity == identity)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._query, _query)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,identity,type,const DeepCollectionEquality().hash(_query),id);

@override
String toString() {
  return 'NotificationPayload(identity: $identity, type: $type, query: $query, id: $id)';
}


}

/// @nodoc
abstract mixin class _$NotificationPayloadCopyWith<$Res> implements $NotificationPayloadCopyWith<$Res> {
  factory _$NotificationPayloadCopyWith(_NotificationPayload value, $Res Function(_NotificationPayload) _then) = __$NotificationPayloadCopyWithImpl;
@override @useResult
$Res call({
 int identity, String type, Map<String, String>? query, int? id
});




}
/// @nodoc
class __$NotificationPayloadCopyWithImpl<$Res>
    implements _$NotificationPayloadCopyWith<$Res> {
  __$NotificationPayloadCopyWithImpl(this._self, this._then);

  final _NotificationPayload _self;
  final $Res Function(_NotificationPayload) _then;

/// Create a copy of NotificationPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? identity = null,Object? type = null,Object? query = freezed,Object? id = freezed,}) {
  return _then(_NotificationPayload(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,query: freezed == query ? _self._query : query // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EnergySummary {

 double get todayEnergyKwh; bool get hasData; DateTime? get lastReadingAt;
/// Create a copy of EnergySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnergySummaryCopyWith<EnergySummary> get copyWith => _$EnergySummaryCopyWithImpl<EnergySummary>(this as EnergySummary, _$identity);

  /// Serializes this EnergySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EnergySummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnergySummary&&(identical(other.todayEnergyKwh, _this.todayEnergyKwh) || other.todayEnergyKwh == _this.todayEnergyKwh)&&(identical(other.hasData, _this.hasData) || other.hasData == _this.hasData)&&(identical(other.lastReadingAt, _this.lastReadingAt) || other.lastReadingAt == _this.lastReadingAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EnergySummary;
  return Object.hash(runtimeType,_this.todayEnergyKwh,_this.hasData,_this.lastReadingAt);
}

@override
String toString() {
  final _this = this as EnergySummary;
  return 'EnergySummary(todayEnergyKwh: ${_this.todayEnergyKwh}, hasData: ${_this.hasData}, lastReadingAt: ${_this.lastReadingAt})';
}


}

/// @nodoc
abstract mixin class $EnergySummaryCopyWith<$Res>  {
  factory $EnergySummaryCopyWith(EnergySummary value, $Res Function(EnergySummary) _then) = _$EnergySummaryCopyWithImpl;
@useResult
$Res call({
 double todayEnergyKwh, bool hasData, DateTime? lastReadingAt
});




}
/// @nodoc
class _$EnergySummaryCopyWithImpl<$Res>
    implements $EnergySummaryCopyWith<$Res> {
  _$EnergySummaryCopyWithImpl(this._self, this._then);

  final EnergySummary _self;
  final $Res Function(EnergySummary) _then;

/// Create a copy of EnergySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? todayEnergyKwh = null,Object? hasData = null,Object? lastReadingAt = freezed,}) {
  return _then(EnergySummary(
todayEnergyKwh: null == todayEnergyKwh ? _self.todayEnergyKwh : todayEnergyKwh // ignore: cast_nullable_to_non_nullable
as double,hasData: null == hasData ? _self.hasData : hasData // ignore: cast_nullable_to_non_nullable
as bool,lastReadingAt: freezed == lastReadingAt ? _self.lastReadingAt : lastReadingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [EnergySummary].
extension EnergySummaryPatterns on EnergySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnergySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnergySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnergySummary value)  $default,){
final _that = this;
switch (_that) {
case _EnergySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnergySummary value)?  $default,){
final _that = this;
switch (_that) {
case _EnergySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double todayEnergyKwh,  bool hasData,  DateTime? lastReadingAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnergySummary() when $default != null:
return $default(_that.todayEnergyKwh,_that.hasData,_that.lastReadingAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double todayEnergyKwh,  bool hasData,  DateTime? lastReadingAt)  $default,) {final _that = this;
switch (_that) {
case _EnergySummary():
return $default(_that.todayEnergyKwh,_that.hasData,_that.lastReadingAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double todayEnergyKwh,  bool hasData,  DateTime? lastReadingAt)?  $default,) {final _that = this;
switch (_that) {
case _EnergySummary() when $default != null:
return $default(_that.todayEnergyKwh,_that.hasData,_that.lastReadingAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnergySummary implements EnergySummary {
  const _EnergySummary({this.todayEnergyKwh = 0, this.hasData = false, this.lastReadingAt});
  factory _EnergySummary.fromJson(Map<String, dynamic> json) => _$EnergySummaryFromJson(json);

@override@JsonKey() final  double todayEnergyKwh;
@override@JsonKey() final  bool hasData;
@override final  DateTime? lastReadingAt;

/// Create a copy of EnergySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnergySummaryCopyWith<_EnergySummary> get copyWith => __$EnergySummaryCopyWithImpl<_EnergySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnergySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnergySummary&&(identical(other.todayEnergyKwh, todayEnergyKwh) || other.todayEnergyKwh == todayEnergyKwh)&&(identical(other.hasData, hasData) || other.hasData == hasData)&&(identical(other.lastReadingAt, lastReadingAt) || other.lastReadingAt == lastReadingAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,todayEnergyKwh,hasData,lastReadingAt);
}

@override
String toString() {
    return 'EnergySummary(todayEnergyKwh: $todayEnergyKwh, hasData: $hasData, lastReadingAt: $lastReadingAt)';
}


}

/// @nodoc
abstract mixin class _$EnergySummaryCopyWith<$Res> implements $EnergySummaryCopyWith<$Res> {
  factory _$EnergySummaryCopyWith(_EnergySummary value, $Res Function(_EnergySummary) _then) = __$EnergySummaryCopyWithImpl;
@override @useResult
$Res call({
 double todayEnergyKwh, bool hasData, DateTime? lastReadingAt
});




}
/// @nodoc
class __$EnergySummaryCopyWithImpl<$Res>
    implements _$EnergySummaryCopyWith<$Res> {
  __$EnergySummaryCopyWithImpl(this._self, this._then);

  final _EnergySummary _self;
  final $Res Function(_EnergySummary) _then;

/// Create a copy of EnergySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? todayEnergyKwh = null,Object? hasData = null,Object? lastReadingAt = freezed,}) {
  return _then(_EnergySummary(
todayEnergyKwh: null == todayEnergyKwh ? _self.todayEnergyKwh : todayEnergyKwh // ignore: cast_nullable_to_non_nullable
as double,hasData: null == hasData ? _self.hasData : hasData // ignore: cast_nullable_to_non_nullable
as bool,lastReadingAt: freezed == lastReadingAt ? _self.lastReadingAt : lastReadingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$DashboardAlert {

 String get id;@JsonKey(unknownEnumValue: NotificationType.info) NotificationType get type; String get title; String get message; bool get read; String? get link; DateTime? get createdAt;
/// Create a copy of DashboardAlert
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardAlertCopyWith<DashboardAlert> get copyWith => _$DashboardAlertCopyWithImpl<DashboardAlert>(this as DashboardAlert, _$identity);

  /// Serializes this DashboardAlert to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DashboardAlert;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardAlert&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.read, _this.read) || other.read == _this.read)&&(identical(other.link, _this.link) || other.link == _this.link)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DashboardAlert;
  return Object.hash(runtimeType,_this.id,_this.type,_this.title,_this.message,_this.read,_this.link,_this.createdAt);
}

@override
String toString() {
  final _this = this as DashboardAlert;
  return 'DashboardAlert(id: ${_this.id}, type: ${_this.type}, title: ${_this.title}, message: ${_this.message}, read: ${_this.read}, link: ${_this.link}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $DashboardAlertCopyWith<$Res>  {
  factory $DashboardAlertCopyWith(DashboardAlert value, $Res Function(DashboardAlert) _then) = _$DashboardAlertCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: NotificationType.info) NotificationType type, String title, String message, bool read, String? link, DateTime? createdAt
});




}
/// @nodoc
class _$DashboardAlertCopyWithImpl<$Res>
    implements $DashboardAlertCopyWith<$Res> {
  _$DashboardAlertCopyWithImpl(this._self, this._then);

  final DashboardAlert _self;
  final $Res Function(DashboardAlert) _then;

/// Create a copy of DashboardAlert
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? title = null,Object? message = null,Object? read = null,Object? link = freezed,Object? createdAt = freezed,}) {
  return _then(DashboardAlert(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NotificationType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,read: null == read ? _self.read : read // ignore: cast_nullable_to_non_nullable
as bool,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardAlert].
extension DashboardAlertPatterns on DashboardAlert {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardAlert value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardAlert() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardAlert value)  $default,){
final _that = this;
switch (_that) {
case _DashboardAlert():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardAlert value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardAlert() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: NotificationType.info)  NotificationType type,  String title,  String message,  bool read,  String? link,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardAlert() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.message,_that.read,_that.link,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: NotificationType.info)  NotificationType type,  String title,  String message,  bool read,  String? link,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _DashboardAlert():
return $default(_that.id,_that.type,_that.title,_that.message,_that.read,_that.link,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(unknownEnumValue: NotificationType.info)  NotificationType type,  String title,  String message,  bool read,  String? link,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _DashboardAlert() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.message,_that.read,_that.link,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardAlert implements DashboardAlert {
  const _DashboardAlert({required this.id, @JsonKey(unknownEnumValue: NotificationType.info) this.type = NotificationType.info, required this.title, this.message = '', this.read = false, this.link, this.createdAt});
  factory _DashboardAlert.fromJson(Map<String, dynamic> json) => _$DashboardAlertFromJson(json);

@override final  String id;
@override@JsonKey(unknownEnumValue: NotificationType.info) final  NotificationType type;
@override final  String title;
@override@JsonKey() final  String message;
@override@JsonKey() final  bool read;
@override final  String? link;
@override final  DateTime? createdAt;

/// Create a copy of DashboardAlert
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardAlertCopyWith<_DashboardAlert> get copyWith => __$DashboardAlertCopyWithImpl<_DashboardAlert>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardAlertToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardAlert&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.read, read) || other.read == read)&&(identical(other.link, link) || other.link == link)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,title,message,read,link,createdAt);
}

@override
String toString() {
    return 'DashboardAlert(id: $id, type: $type, title: $title, message: $message, read: $read, link: $link, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$DashboardAlertCopyWith<$Res> implements $DashboardAlertCopyWith<$Res> {
  factory _$DashboardAlertCopyWith(_DashboardAlert value, $Res Function(_DashboardAlert) _then) = __$DashboardAlertCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: NotificationType.info) NotificationType type, String title, String message, bool read, String? link, DateTime? createdAt
});




}
/// @nodoc
class __$DashboardAlertCopyWithImpl<$Res>
    implements _$DashboardAlertCopyWith<$Res> {
  __$DashboardAlertCopyWithImpl(this._self, this._then);

  final _DashboardAlert _self;
  final $Res Function(_DashboardAlert) _then;

/// Create a copy of DashboardAlert
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? title = null,Object? message = null,Object? read = null,Object? link = freezed,Object? createdAt = freezed,}) {
  return _then(_DashboardAlert(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NotificationType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,read: null == read ? _self.read : read // ignore: cast_nullable_to_non_nullable
as bool,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

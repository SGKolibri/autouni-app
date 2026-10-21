// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'energy_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EnergyStats {

 double get totalKwh;@JsonKey(name: 'count') int get readingCount; double? get avgWh; double? get maxWh; double? get minWh; int? get totalDevices; int? get activeDevices;@JsonKey(name: 'hasData') bool? get reportedHasData;
/// Create a copy of EnergyStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnergyStatsCopyWith<EnergyStats> get copyWith => _$EnergyStatsCopyWithImpl<EnergyStats>(this as EnergyStats, _$identity);

  /// Serializes this EnergyStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EnergyStats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnergyStats&&(identical(other.totalKwh, _this.totalKwh) || other.totalKwh == _this.totalKwh)&&(identical(other.readingCount, _this.readingCount) || other.readingCount == _this.readingCount)&&(identical(other.avgWh, _this.avgWh) || other.avgWh == _this.avgWh)&&(identical(other.maxWh, _this.maxWh) || other.maxWh == _this.maxWh)&&(identical(other.minWh, _this.minWh) || other.minWh == _this.minWh)&&(identical(other.totalDevices, _this.totalDevices) || other.totalDevices == _this.totalDevices)&&(identical(other.activeDevices, _this.activeDevices) || other.activeDevices == _this.activeDevices)&&(identical(other.reportedHasData, _this.reportedHasData) || other.reportedHasData == _this.reportedHasData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EnergyStats;
  return Object.hash(runtimeType,_this.totalKwh,_this.readingCount,_this.avgWh,_this.maxWh,_this.minWh,_this.totalDevices,_this.activeDevices,_this.reportedHasData);
}

@override
String toString() {
  final _this = this as EnergyStats;
  return 'EnergyStats(totalKwh: ${_this.totalKwh}, readingCount: ${_this.readingCount}, avgWh: ${_this.avgWh}, maxWh: ${_this.maxWh}, minWh: ${_this.minWh}, totalDevices: ${_this.totalDevices}, activeDevices: ${_this.activeDevices}, reportedHasData: ${_this.reportedHasData})';
}


}

/// @nodoc
abstract mixin class $EnergyStatsCopyWith<$Res>  {
  factory $EnergyStatsCopyWith(EnergyStats value, $Res Function(EnergyStats) _then) = _$EnergyStatsCopyWithImpl;
@useResult
$Res call({
 double totalKwh,@JsonKey(name: 'count') int readingCount, double? avgWh, double? maxWh, double? minWh, int? totalDevices, int? activeDevices,@JsonKey(name: 'hasData') bool? reportedHasData
});




}
/// @nodoc
class _$EnergyStatsCopyWithImpl<$Res>
    implements $EnergyStatsCopyWith<$Res> {
  _$EnergyStatsCopyWithImpl(this._self, this._then);

  final EnergyStats _self;
  final $Res Function(EnergyStats) _then;

/// Create a copy of EnergyStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalKwh = null,Object? readingCount = null,Object? avgWh = freezed,Object? maxWh = freezed,Object? minWh = freezed,Object? totalDevices = freezed,Object? activeDevices = freezed,Object? reportedHasData = freezed,}) {
  return _then(EnergyStats(
totalKwh: null == totalKwh ? _self.totalKwh : totalKwh // ignore: cast_nullable_to_non_nullable
as double,readingCount: null == readingCount ? _self.readingCount : readingCount // ignore: cast_nullable_to_non_nullable
as int,avgWh: freezed == avgWh ? _self.avgWh : avgWh // ignore: cast_nullable_to_non_nullable
as double?,maxWh: freezed == maxWh ? _self.maxWh : maxWh // ignore: cast_nullable_to_non_nullable
as double?,minWh: freezed == minWh ? _self.minWh : minWh // ignore: cast_nullable_to_non_nullable
as double?,totalDevices: freezed == totalDevices ? _self.totalDevices : totalDevices // ignore: cast_nullable_to_non_nullable
as int?,activeDevices: freezed == activeDevices ? _self.activeDevices : activeDevices // ignore: cast_nullable_to_non_nullable
as int?,reportedHasData: freezed == reportedHasData ? _self.reportedHasData : reportedHasData // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [EnergyStats].
extension EnergyStatsPatterns on EnergyStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnergyStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnergyStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnergyStats value)  $default,){
final _that = this;
switch (_that) {
case _EnergyStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnergyStats value)?  $default,){
final _that = this;
switch (_that) {
case _EnergyStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double totalKwh, @JsonKey(name: 'count')  int readingCount,  double? avgWh,  double? maxWh,  double? minWh,  int? totalDevices,  int? activeDevices, @JsonKey(name: 'hasData')  bool? reportedHasData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnergyStats() when $default != null:
return $default(_that.totalKwh,_that.readingCount,_that.avgWh,_that.maxWh,_that.minWh,_that.totalDevices,_that.activeDevices,_that.reportedHasData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double totalKwh, @JsonKey(name: 'count')  int readingCount,  double? avgWh,  double? maxWh,  double? minWh,  int? totalDevices,  int? activeDevices, @JsonKey(name: 'hasData')  bool? reportedHasData)  $default,) {final _that = this;
switch (_that) {
case _EnergyStats():
return $default(_that.totalKwh,_that.readingCount,_that.avgWh,_that.maxWh,_that.minWh,_that.totalDevices,_that.activeDevices,_that.reportedHasData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double totalKwh, @JsonKey(name: 'count')  int readingCount,  double? avgWh,  double? maxWh,  double? minWh,  int? totalDevices,  int? activeDevices, @JsonKey(name: 'hasData')  bool? reportedHasData)?  $default,) {final _that = this;
switch (_that) {
case _EnergyStats() when $default != null:
return $default(_that.totalKwh,_that.readingCount,_that.avgWh,_that.maxWh,_that.minWh,_that.totalDevices,_that.activeDevices,_that.reportedHasData);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnergyStats extends EnergyStats {
  const _EnergyStats({this.totalKwh = 0, @JsonKey(name: 'count') this.readingCount = 0, this.avgWh, this.maxWh, this.minWh, this.totalDevices, this.activeDevices, @JsonKey(name: 'hasData') this.reportedHasData}): super._();
  factory _EnergyStats.fromJson(Map<String, dynamic> json) => _$EnergyStatsFromJson(json);

@override@JsonKey() final  double totalKwh;
@override@JsonKey(name: 'count') final  int readingCount;
@override final  double? avgWh;
@override final  double? maxWh;
@override final  double? minWh;
@override final  int? totalDevices;
@override final  int? activeDevices;
@override@JsonKey(name: 'hasData') final  bool? reportedHasData;

/// Create a copy of EnergyStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnergyStatsCopyWith<_EnergyStats> get copyWith => __$EnergyStatsCopyWithImpl<_EnergyStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnergyStatsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnergyStats&&(identical(other.totalKwh, totalKwh) || other.totalKwh == totalKwh)&&(identical(other.readingCount, readingCount) || other.readingCount == readingCount)&&(identical(other.avgWh, avgWh) || other.avgWh == avgWh)&&(identical(other.maxWh, maxWh) || other.maxWh == maxWh)&&(identical(other.minWh, minWh) || other.minWh == minWh)&&(identical(other.totalDevices, totalDevices) || other.totalDevices == totalDevices)&&(identical(other.activeDevices, activeDevices) || other.activeDevices == activeDevices)&&(identical(other.reportedHasData, reportedHasData) || other.reportedHasData == reportedHasData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,totalKwh,readingCount,avgWh,maxWh,minWh,totalDevices,activeDevices,reportedHasData);
}

@override
String toString() {
    return 'EnergyStats(totalKwh: $totalKwh, readingCount: $readingCount, avgWh: $avgWh, maxWh: $maxWh, minWh: $minWh, totalDevices: $totalDevices, activeDevices: $activeDevices, reportedHasData: $reportedHasData)';
}


}

/// @nodoc
abstract mixin class _$EnergyStatsCopyWith<$Res> implements $EnergyStatsCopyWith<$Res> {
  factory _$EnergyStatsCopyWith(_EnergyStats value, $Res Function(_EnergyStats) _then) = __$EnergyStatsCopyWithImpl;
@override @useResult
$Res call({
 double totalKwh,@JsonKey(name: 'count') int readingCount, double? avgWh, double? maxWh, double? minWh, int? totalDevices, int? activeDevices,@JsonKey(name: 'hasData') bool? reportedHasData
});




}
/// @nodoc
class __$EnergyStatsCopyWithImpl<$Res>
    implements _$EnergyStatsCopyWith<$Res> {
  __$EnergyStatsCopyWithImpl(this._self, this._then);

  final _EnergyStats _self;
  final $Res Function(_EnergyStats) _then;

/// Create a copy of EnergyStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalKwh = null,Object? readingCount = null,Object? avgWh = freezed,Object? maxWh = freezed,Object? minWh = freezed,Object? totalDevices = freezed,Object? activeDevices = freezed,Object? reportedHasData = freezed,}) {
  return _then(_EnergyStats(
totalKwh: null == totalKwh ? _self.totalKwh : totalKwh // ignore: cast_nullable_to_non_nullable
as double,readingCount: null == readingCount ? _self.readingCount : readingCount // ignore: cast_nullable_to_non_nullable
as int,avgWh: freezed == avgWh ? _self.avgWh : avgWh // ignore: cast_nullable_to_non_nullable
as double?,maxWh: freezed == maxWh ? _self.maxWh : maxWh // ignore: cast_nullable_to_non_nullable
as double?,minWh: freezed == minWh ? _self.minWh : minWh // ignore: cast_nullable_to_non_nullable
as double?,totalDevices: freezed == totalDevices ? _self.totalDevices : totalDevices // ignore: cast_nullable_to_non_nullable
as int?,activeDevices: freezed == activeDevices ? _self.activeDevices : activeDevices // ignore: cast_nullable_to_non_nullable
as int?,reportedHasData: freezed == reportedHasData ? _self.reportedHasData : reportedHasData // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}


/// @nodoc
mixin _$EnergyHistoryPoint {

 DateTime get bucket; double get totalKwh; int get count;
/// Create a copy of EnergyHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnergyHistoryPointCopyWith<EnergyHistoryPoint> get copyWith => _$EnergyHistoryPointCopyWithImpl<EnergyHistoryPoint>(this as EnergyHistoryPoint, _$identity);

  /// Serializes this EnergyHistoryPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EnergyHistoryPoint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnergyHistoryPoint&&(identical(other.bucket, _this.bucket) || other.bucket == _this.bucket)&&(identical(other.totalKwh, _this.totalKwh) || other.totalKwh == _this.totalKwh)&&(identical(other.count, _this.count) || other.count == _this.count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EnergyHistoryPoint;
  return Object.hash(runtimeType,_this.bucket,_this.totalKwh,_this.count);
}

@override
String toString() {
  final _this = this as EnergyHistoryPoint;
  return 'EnergyHistoryPoint(bucket: ${_this.bucket}, totalKwh: ${_this.totalKwh}, count: ${_this.count})';
}


}

/// @nodoc
abstract mixin class $EnergyHistoryPointCopyWith<$Res>  {
  factory $EnergyHistoryPointCopyWith(EnergyHistoryPoint value, $Res Function(EnergyHistoryPoint) _then) = _$EnergyHistoryPointCopyWithImpl;
@useResult
$Res call({
 DateTime bucket, double totalKwh, int count
});




}
/// @nodoc
class _$EnergyHistoryPointCopyWithImpl<$Res>
    implements $EnergyHistoryPointCopyWith<$Res> {
  _$EnergyHistoryPointCopyWithImpl(this._self, this._then);

  final EnergyHistoryPoint _self;
  final $Res Function(EnergyHistoryPoint) _then;

/// Create a copy of EnergyHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bucket = null,Object? totalKwh = null,Object? count = null,}) {
  return _then(EnergyHistoryPoint(
bucket: null == bucket ? _self.bucket : bucket // ignore: cast_nullable_to_non_nullable
as DateTime,totalKwh: null == totalKwh ? _self.totalKwh : totalKwh // ignore: cast_nullable_to_non_nullable
as double,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EnergyHistoryPoint].
extension EnergyHistoryPointPatterns on EnergyHistoryPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnergyHistoryPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnergyHistoryPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnergyHistoryPoint value)  $default,){
final _that = this;
switch (_that) {
case _EnergyHistoryPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnergyHistoryPoint value)?  $default,){
final _that = this;
switch (_that) {
case _EnergyHistoryPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime bucket,  double totalKwh,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnergyHistoryPoint() when $default != null:
return $default(_that.bucket,_that.totalKwh,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime bucket,  double totalKwh,  int count)  $default,) {final _that = this;
switch (_that) {
case _EnergyHistoryPoint():
return $default(_that.bucket,_that.totalKwh,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime bucket,  double totalKwh,  int count)?  $default,) {final _that = this;
switch (_that) {
case _EnergyHistoryPoint() when $default != null:
return $default(_that.bucket,_that.totalKwh,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnergyHistoryPoint extends EnergyHistoryPoint {
  const _EnergyHistoryPoint({required this.bucket, this.totalKwh = 0, this.count = 0}): super._();
  factory _EnergyHistoryPoint.fromJson(Map<String, dynamic> json) => _$EnergyHistoryPointFromJson(json);

@override final  DateTime bucket;
@override@JsonKey() final  double totalKwh;
@override@JsonKey() final  int count;

/// Create a copy of EnergyHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnergyHistoryPointCopyWith<_EnergyHistoryPoint> get copyWith => __$EnergyHistoryPointCopyWithImpl<_EnergyHistoryPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnergyHistoryPointToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnergyHistoryPoint&&(identical(other.bucket, bucket) || other.bucket == bucket)&&(identical(other.totalKwh, totalKwh) || other.totalKwh == totalKwh)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,bucket,totalKwh,count);
}

@override
String toString() {
    return 'EnergyHistoryPoint(bucket: $bucket, totalKwh: $totalKwh, count: $count)';
}


}

/// @nodoc
abstract mixin class _$EnergyHistoryPointCopyWith<$Res> implements $EnergyHistoryPointCopyWith<$Res> {
  factory _$EnergyHistoryPointCopyWith(_EnergyHistoryPoint value, $Res Function(_EnergyHistoryPoint) _then) = __$EnergyHistoryPointCopyWithImpl;
@override @useResult
$Res call({
 DateTime bucket, double totalKwh, int count
});




}
/// @nodoc
class __$EnergyHistoryPointCopyWithImpl<$Res>
    implements _$EnergyHistoryPointCopyWith<$Res> {
  __$EnergyHistoryPointCopyWithImpl(this._self, this._then);

  final _EnergyHistoryPoint _self;
  final $Res Function(_EnergyHistoryPoint) _then;

/// Create a copy of EnergyHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bucket = null,Object? totalKwh = null,Object? count = null,}) {
  return _then(_EnergyHistoryPoint(
bucket: null == bucket ? _self.bucket : bucket // ignore: cast_nullable_to_non_nullable
as DateTime,totalKwh: null == totalKwh ? _self.totalKwh : totalKwh // ignore: cast_nullable_to_non_nullable
as double,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$EnergyRankingItem {

 String get id;@JsonKey(fromJson: _displayName) String get name; double get totalKwh;
/// Create a copy of EnergyRankingItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnergyRankingItemCopyWith<EnergyRankingItem> get copyWith => _$EnergyRankingItemCopyWithImpl<EnergyRankingItem>(this as EnergyRankingItem, _$identity);

  /// Serializes this EnergyRankingItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EnergyRankingItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnergyRankingItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.totalKwh, _this.totalKwh) || other.totalKwh == _this.totalKwh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EnergyRankingItem;
  return Object.hash(runtimeType,_this.id,_this.name,_this.totalKwh);
}

@override
String toString() {
  final _this = this as EnergyRankingItem;
  return 'EnergyRankingItem(id: ${_this.id}, name: ${_this.name}, totalKwh: ${_this.totalKwh})';
}


}

/// @nodoc
abstract mixin class $EnergyRankingItemCopyWith<$Res>  {
  factory $EnergyRankingItemCopyWith(EnergyRankingItem value, $Res Function(EnergyRankingItem) _then) = _$EnergyRankingItemCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(fromJson: _displayName) String name, double totalKwh
});




}
/// @nodoc
class _$EnergyRankingItemCopyWithImpl<$Res>
    implements $EnergyRankingItemCopyWith<$Res> {
  _$EnergyRankingItemCopyWithImpl(this._self, this._then);

  final EnergyRankingItem _self;
  final $Res Function(EnergyRankingItem) _then;

/// Create a copy of EnergyRankingItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? totalKwh = null,}) {
  return _then(EnergyRankingItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,totalKwh: null == totalKwh ? _self.totalKwh : totalKwh // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [EnergyRankingItem].
extension EnergyRankingItemPatterns on EnergyRankingItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnergyRankingItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnergyRankingItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnergyRankingItem value)  $default,){
final _that = this;
switch (_that) {
case _EnergyRankingItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnergyRankingItem value)?  $default,){
final _that = this;
switch (_that) {
case _EnergyRankingItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(fromJson: _displayName)  String name,  double totalKwh)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnergyRankingItem() when $default != null:
return $default(_that.id,_that.name,_that.totalKwh);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(fromJson: _displayName)  String name,  double totalKwh)  $default,) {final _that = this;
switch (_that) {
case _EnergyRankingItem():
return $default(_that.id,_that.name,_that.totalKwh);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(fromJson: _displayName)  String name,  double totalKwh)?  $default,) {final _that = this;
switch (_that) {
case _EnergyRankingItem() when $default != null:
return $default(_that.id,_that.name,_that.totalKwh);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnergyRankingItem implements EnergyRankingItem {
  const _EnergyRankingItem({required this.id, @JsonKey(fromJson: _displayName) required this.name, this.totalKwh = 0});
  factory _EnergyRankingItem.fromJson(Map<String, dynamic> json) => _$EnergyRankingItemFromJson(json);

@override final  String id;
@override@JsonKey(fromJson: _displayName) final  String name;
@override@JsonKey() final  double totalKwh;

/// Create a copy of EnergyRankingItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnergyRankingItemCopyWith<_EnergyRankingItem> get copyWith => __$EnergyRankingItemCopyWithImpl<_EnergyRankingItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnergyRankingItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnergyRankingItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.totalKwh, totalKwh) || other.totalKwh == totalKwh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,totalKwh);
}

@override
String toString() {
    return 'EnergyRankingItem(id: $id, name: $name, totalKwh: $totalKwh)';
}


}

/// @nodoc
abstract mixin class _$EnergyRankingItemCopyWith<$Res> implements $EnergyRankingItemCopyWith<$Res> {
  factory _$EnergyRankingItemCopyWith(_EnergyRankingItem value, $Res Function(_EnergyRankingItem) _then) = __$EnergyRankingItemCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(fromJson: _displayName) String name, double totalKwh
});




}
/// @nodoc
class __$EnergyRankingItemCopyWithImpl<$Res>
    implements _$EnergyRankingItemCopyWith<$Res> {
  __$EnergyRankingItemCopyWithImpl(this._self, this._then);

  final _EnergyRankingItem _self;
  final $Res Function(_EnergyRankingItem) _then;

/// Create a copy of EnergyRankingItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? totalKwh = null,}) {
  return _then(_EnergyRankingItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,totalKwh: null == totalKwh ? _self.totalKwh : totalKwh // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'campus_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Building {

 String get id; String get name; String? get description; String get location; List<Floor> get floors; int get totalDevices; int get activeDevices; double get todayEnergyKwh; DateTime? get lastReadingAt;
/// Create a copy of Building
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildingCopyWith<Building> get copyWith => _$BuildingCopyWithImpl<Building>(this as Building, _$identity);

  /// Serializes this Building to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Building;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Building&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.location, _this.location) || other.location == _this.location)&&const DeepCollectionEquality().equals(other.floors, _this.floors)&&(identical(other.totalDevices, _this.totalDevices) || other.totalDevices == _this.totalDevices)&&(identical(other.activeDevices, _this.activeDevices) || other.activeDevices == _this.activeDevices)&&(identical(other.todayEnergyKwh, _this.todayEnergyKwh) || other.todayEnergyKwh == _this.todayEnergyKwh)&&(identical(other.lastReadingAt, _this.lastReadingAt) || other.lastReadingAt == _this.lastReadingAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Building;
  return Object.hash(runtimeType,_this.id,_this.name,_this.description,_this.location,const DeepCollectionEquality().hash(_this.floors),_this.totalDevices,_this.activeDevices,_this.todayEnergyKwh,_this.lastReadingAt);
}

@override
String toString() {
  final _this = this as Building;
  return 'Building(id: ${_this.id}, name: ${_this.name}, description: ${_this.description}, location: ${_this.location}, floors: ${_this.floors}, totalDevices: ${_this.totalDevices}, activeDevices: ${_this.activeDevices}, todayEnergyKwh: ${_this.todayEnergyKwh}, lastReadingAt: ${_this.lastReadingAt})';
}


}

/// @nodoc
abstract mixin class $BuildingCopyWith<$Res>  {
  factory $BuildingCopyWith(Building value, $Res Function(Building) _then) = _$BuildingCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, String location, List<Floor> floors, int totalDevices, int activeDevices, double todayEnergyKwh, DateTime? lastReadingAt
});




}
/// @nodoc
class _$BuildingCopyWithImpl<$Res>
    implements $BuildingCopyWith<$Res> {
  _$BuildingCopyWithImpl(this._self, this._then);

  final Building _self;
  final $Res Function(Building) _then;

/// Create a copy of Building
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? location = null,Object? floors = null,Object? totalDevices = null,Object? activeDevices = null,Object? todayEnergyKwh = null,Object? lastReadingAt = freezed,}) {
  return _then(Building(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,floors: null == floors ? _self.floors : floors // ignore: cast_nullable_to_non_nullable
as List<Floor>,totalDevices: null == totalDevices ? _self.totalDevices : totalDevices // ignore: cast_nullable_to_non_nullable
as int,activeDevices: null == activeDevices ? _self.activeDevices : activeDevices // ignore: cast_nullable_to_non_nullable
as int,todayEnergyKwh: null == todayEnergyKwh ? _self.todayEnergyKwh : todayEnergyKwh // ignore: cast_nullable_to_non_nullable
as double,lastReadingAt: freezed == lastReadingAt ? _self.lastReadingAt : lastReadingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Building].
extension BuildingPatterns on Building {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Building value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Building() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Building value)  $default,){
final _that = this;
switch (_that) {
case _Building():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Building value)?  $default,){
final _that = this;
switch (_that) {
case _Building() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String location,  List<Floor> floors,  int totalDevices,  int activeDevices,  double todayEnergyKwh,  DateTime? lastReadingAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Building() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.location,_that.floors,_that.totalDevices,_that.activeDevices,_that.todayEnergyKwh,_that.lastReadingAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String location,  List<Floor> floors,  int totalDevices,  int activeDevices,  double todayEnergyKwh,  DateTime? lastReadingAt)  $default,) {final _that = this;
switch (_that) {
case _Building():
return $default(_that.id,_that.name,_that.description,_that.location,_that.floors,_that.totalDevices,_that.activeDevices,_that.todayEnergyKwh,_that.lastReadingAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  String location,  List<Floor> floors,  int totalDevices,  int activeDevices,  double todayEnergyKwh,  DateTime? lastReadingAt)?  $default,) {final _that = this;
switch (_that) {
case _Building() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.location,_that.floors,_that.totalDevices,_that.activeDevices,_that.todayEnergyKwh,_that.lastReadingAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Building implements Building {
  const _Building({required this.id, required this.name, this.description, this.location = '',  List<Floor> floors = const <Floor>[], this.totalDevices = 0, this.activeDevices = 0, this.todayEnergyKwh = 0, this.lastReadingAt}): _floors = floors;
  factory _Building.fromJson(Map<String, dynamic> json) => _$BuildingFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? description;
@override@JsonKey() final  String location;
 final  List<Floor> _floors;
@override@JsonKey() List<Floor> get floors {
  if (_floors is EqualUnmodifiableListView) return _floors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_floors);
}

@override@JsonKey() final  int totalDevices;
@override@JsonKey() final  int activeDevices;
@override@JsonKey() final  double todayEnergyKwh;
@override final  DateTime? lastReadingAt;

/// Create a copy of Building
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuildingCopyWith<_Building> get copyWith => __$BuildingCopyWithImpl<_Building>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuildingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Building&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other.floors, _floors)&&(identical(other.totalDevices, totalDevices) || other.totalDevices == totalDevices)&&(identical(other.activeDevices, activeDevices) || other.activeDevices == activeDevices)&&(identical(other.todayEnergyKwh, todayEnergyKwh) || other.todayEnergyKwh == todayEnergyKwh)&&(identical(other.lastReadingAt, lastReadingAt) || other.lastReadingAt == lastReadingAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,description,location,const DeepCollectionEquality().hash(_floors),totalDevices,activeDevices,todayEnergyKwh,lastReadingAt);
}

@override
String toString() {
    return 'Building(id: $id, name: $name, description: $description, location: $location, floors: $floors, totalDevices: $totalDevices, activeDevices: $activeDevices, todayEnergyKwh: $todayEnergyKwh, lastReadingAt: $lastReadingAt)';
}


}

/// @nodoc
abstract mixin class _$BuildingCopyWith<$Res> implements $BuildingCopyWith<$Res> {
  factory _$BuildingCopyWith(_Building value, $Res Function(_Building) _then) = __$BuildingCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, String location, List<Floor> floors, int totalDevices, int activeDevices, double todayEnergyKwh, DateTime? lastReadingAt
});




}
/// @nodoc
class __$BuildingCopyWithImpl<$Res>
    implements _$BuildingCopyWith<$Res> {
  __$BuildingCopyWithImpl(this._self, this._then);

  final _Building _self;
  final $Res Function(_Building) _then;

/// Create a copy of Building
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? location = null,Object? floors = null,Object? totalDevices = null,Object? activeDevices = null,Object? todayEnergyKwh = null,Object? lastReadingAt = freezed,}) {
  return _then(_Building(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,floors: null == floors ? _self._floors : floors // ignore: cast_nullable_to_non_nullable
as List<Floor>,totalDevices: null == totalDevices ? _self.totalDevices : totalDevices // ignore: cast_nullable_to_non_nullable
as int,activeDevices: null == activeDevices ? _self.activeDevices : activeDevices // ignore: cast_nullable_to_non_nullable
as int,todayEnergyKwh: null == todayEnergyKwh ? _self.todayEnergyKwh : todayEnergyKwh // ignore: cast_nullable_to_non_nullable
as double,lastReadingAt: freezed == lastReadingAt ? _self.lastReadingAt : lastReadingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Floor {

 String get id; String get buildingId; int get number; String? get name; Building? get building; List<Room> get rooms; int get totalDevices; int get activeDevices; double get todayEnergyKwh;
/// Create a copy of Floor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FloorCopyWith<Floor> get copyWith => _$FloorCopyWithImpl<Floor>(this as Floor, _$identity);

  /// Serializes this Floor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Floor;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Floor&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.buildingId, _this.buildingId) || other.buildingId == _this.buildingId)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.building, _this.building) || other.building == _this.building)&&const DeepCollectionEquality().equals(other.rooms, _this.rooms)&&(identical(other.totalDevices, _this.totalDevices) || other.totalDevices == _this.totalDevices)&&(identical(other.activeDevices, _this.activeDevices) || other.activeDevices == _this.activeDevices)&&(identical(other.todayEnergyKwh, _this.todayEnergyKwh) || other.todayEnergyKwh == _this.todayEnergyKwh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Floor;
  return Object.hash(runtimeType,_this.id,_this.buildingId,_this.number,_this.name,_this.building,const DeepCollectionEquality().hash(_this.rooms),_this.totalDevices,_this.activeDevices,_this.todayEnergyKwh);
}

@override
String toString() {
  final _this = this as Floor;
  return 'Floor(id: ${_this.id}, buildingId: ${_this.buildingId}, number: ${_this.number}, name: ${_this.name}, building: ${_this.building}, rooms: ${_this.rooms}, totalDevices: ${_this.totalDevices}, activeDevices: ${_this.activeDevices}, todayEnergyKwh: ${_this.todayEnergyKwh})';
}


}

/// @nodoc
abstract mixin class $FloorCopyWith<$Res>  {
  factory $FloorCopyWith(Floor value, $Res Function(Floor) _then) = _$FloorCopyWithImpl;
@useResult
$Res call({
 String id, String buildingId, int number, String? name, Building? building, List<Room> rooms, int totalDevices, int activeDevices, double todayEnergyKwh
});


$BuildingCopyWith<$Res>? get building;

}
/// @nodoc
class _$FloorCopyWithImpl<$Res>
    implements $FloorCopyWith<$Res> {
  _$FloorCopyWithImpl(this._self, this._then);

  final Floor _self;
  final $Res Function(Floor) _then;

/// Create a copy of Floor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? buildingId = null,Object? number = null,Object? name = freezed,Object? building = freezed,Object? rooms = null,Object? totalDevices = null,Object? activeDevices = null,Object? todayEnergyKwh = null,}) {
  return _then(Floor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buildingId: null == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,building: freezed == building ? _self.building : building // ignore: cast_nullable_to_non_nullable
as Building?,rooms: null == rooms ? _self.rooms : rooms // ignore: cast_nullable_to_non_nullable
as List<Room>,totalDevices: null == totalDevices ? _self.totalDevices : totalDevices // ignore: cast_nullable_to_non_nullable
as int,activeDevices: null == activeDevices ? _self.activeDevices : activeDevices // ignore: cast_nullable_to_non_nullable
as int,todayEnergyKwh: null == todayEnergyKwh ? _self.todayEnergyKwh : todayEnergyKwh // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of Floor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuildingCopyWith<$Res>? get building {
    if (_self.building == null) {
    return null;
  }

  return $BuildingCopyWith<$Res>(_self.building!, (value) {
    return _then(_self.copyWith(building: value));
  });
}
}


/// Adds pattern-matching-related methods to [Floor].
extension FloorPatterns on Floor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Floor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Floor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Floor value)  $default,){
final _that = this;
switch (_that) {
case _Floor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Floor value)?  $default,){
final _that = this;
switch (_that) {
case _Floor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String buildingId,  int number,  String? name,  Building? building,  List<Room> rooms,  int totalDevices,  int activeDevices,  double todayEnergyKwh)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Floor() when $default != null:
return $default(_that.id,_that.buildingId,_that.number,_that.name,_that.building,_that.rooms,_that.totalDevices,_that.activeDevices,_that.todayEnergyKwh);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String buildingId,  int number,  String? name,  Building? building,  List<Room> rooms,  int totalDevices,  int activeDevices,  double todayEnergyKwh)  $default,) {final _that = this;
switch (_that) {
case _Floor():
return $default(_that.id,_that.buildingId,_that.number,_that.name,_that.building,_that.rooms,_that.totalDevices,_that.activeDevices,_that.todayEnergyKwh);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String buildingId,  int number,  String? name,  Building? building,  List<Room> rooms,  int totalDevices,  int activeDevices,  double todayEnergyKwh)?  $default,) {final _that = this;
switch (_that) {
case _Floor() when $default != null:
return $default(_that.id,_that.buildingId,_that.number,_that.name,_that.building,_that.rooms,_that.totalDevices,_that.activeDevices,_that.todayEnergyKwh);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Floor extends Floor {
  const _Floor({required this.id, required this.buildingId, required this.number, this.name, this.building,  List<Room> rooms = const <Room>[], this.totalDevices = 0, this.activeDevices = 0, this.todayEnergyKwh = 0}): _rooms = rooms,super._();
  factory _Floor.fromJson(Map<String, dynamic> json) => _$FloorFromJson(json);

@override final  String id;
@override final  String buildingId;
@override final  int number;
@override final  String? name;
@override final  Building? building;
 final  List<Room> _rooms;
@override@JsonKey() List<Room> get rooms {
  if (_rooms is EqualUnmodifiableListView) return _rooms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rooms);
}

@override@JsonKey() final  int totalDevices;
@override@JsonKey() final  int activeDevices;
@override@JsonKey() final  double todayEnergyKwh;

/// Create a copy of Floor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FloorCopyWith<_Floor> get copyWith => __$FloorCopyWithImpl<_Floor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FloorToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Floor&&(identical(other.id, id) || other.id == id)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.number, number) || other.number == number)&&(identical(other.name, name) || other.name == name)&&(identical(other.building, building) || other.building == building)&&const DeepCollectionEquality().equals(other.rooms, _rooms)&&(identical(other.totalDevices, totalDevices) || other.totalDevices == totalDevices)&&(identical(other.activeDevices, activeDevices) || other.activeDevices == activeDevices)&&(identical(other.todayEnergyKwh, todayEnergyKwh) || other.todayEnergyKwh == todayEnergyKwh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,buildingId,number,name,building,const DeepCollectionEquality().hash(_rooms),totalDevices,activeDevices,todayEnergyKwh);
}

@override
String toString() {
    return 'Floor(id: $id, buildingId: $buildingId, number: $number, name: $name, building: $building, rooms: $rooms, totalDevices: $totalDevices, activeDevices: $activeDevices, todayEnergyKwh: $todayEnergyKwh)';
}


}

/// @nodoc
abstract mixin class _$FloorCopyWith<$Res> implements $FloorCopyWith<$Res> {
  factory _$FloorCopyWith(_Floor value, $Res Function(_Floor) _then) = __$FloorCopyWithImpl;
@override @useResult
$Res call({
 String id, String buildingId, int number, String? name, Building? building, List<Room> rooms, int totalDevices, int activeDevices, double todayEnergyKwh
});


@override $BuildingCopyWith<$Res>? get building;

}
/// @nodoc
class __$FloorCopyWithImpl<$Res>
    implements _$FloorCopyWith<$Res> {
  __$FloorCopyWithImpl(this._self, this._then);

  final _Floor _self;
  final $Res Function(_Floor) _then;

/// Create a copy of Floor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? buildingId = null,Object? number = null,Object? name = freezed,Object? building = freezed,Object? rooms = null,Object? totalDevices = null,Object? activeDevices = null,Object? todayEnergyKwh = null,}) {
  return _then(_Floor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buildingId: null == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,building: freezed == building ? _self.building : building // ignore: cast_nullable_to_non_nullable
as Building?,rooms: null == rooms ? _self._rooms : rooms // ignore: cast_nullable_to_non_nullable
as List<Room>,totalDevices: null == totalDevices ? _self.totalDevices : totalDevices // ignore: cast_nullable_to_non_nullable
as int,activeDevices: null == activeDevices ? _self.activeDevices : activeDevices // ignore: cast_nullable_to_non_nullable
as int,todayEnergyKwh: null == todayEnergyKwh ? _self.todayEnergyKwh : todayEnergyKwh // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of Floor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuildingCopyWith<$Res>? get building {
    if (_self.building == null) {
    return null;
  }

  return $BuildingCopyWith<$Res>(_self.building!, (value) {
    return _then(_self.copyWith(building: value));
  });
}
}


/// @nodoc
mixin _$Room {

 String get id; String get floorId; String get name;@JsonKey(unknownEnumValue: RoomType.other) RoomType get type; Floor? get floor; List<Device> get devices; int get totalDevices; int get activeDevices; double get todayEnergyKwh;
/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomCopyWith<Room> get copyWith => _$RoomCopyWithImpl<Room>(this as Room, _$identity);

  /// Serializes this Room to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Room;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Room&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.floorId, _this.floorId) || other.floorId == _this.floorId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.floor, _this.floor) || other.floor == _this.floor)&&const DeepCollectionEquality().equals(other.devices, _this.devices)&&(identical(other.totalDevices, _this.totalDevices) || other.totalDevices == _this.totalDevices)&&(identical(other.activeDevices, _this.activeDevices) || other.activeDevices == _this.activeDevices)&&(identical(other.todayEnergyKwh, _this.todayEnergyKwh) || other.todayEnergyKwh == _this.todayEnergyKwh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Room;
  return Object.hash(runtimeType,_this.id,_this.floorId,_this.name,_this.type,_this.floor,const DeepCollectionEquality().hash(_this.devices),_this.totalDevices,_this.activeDevices,_this.todayEnergyKwh);
}

@override
String toString() {
  final _this = this as Room;
  return 'Room(id: ${_this.id}, floorId: ${_this.floorId}, name: ${_this.name}, type: ${_this.type}, floor: ${_this.floor}, devices: ${_this.devices}, totalDevices: ${_this.totalDevices}, activeDevices: ${_this.activeDevices}, todayEnergyKwh: ${_this.todayEnergyKwh})';
}


}

/// @nodoc
abstract mixin class $RoomCopyWith<$Res>  {
  factory $RoomCopyWith(Room value, $Res Function(Room) _then) = _$RoomCopyWithImpl;
@useResult
$Res call({
 String id, String floorId, String name,@JsonKey(unknownEnumValue: RoomType.other) RoomType type, Floor? floor, List<Device> devices, int totalDevices, int activeDevices, double todayEnergyKwh
});


$FloorCopyWith<$Res>? get floor;

}
/// @nodoc
class _$RoomCopyWithImpl<$Res>
    implements $RoomCopyWith<$Res> {
  _$RoomCopyWithImpl(this._self, this._then);

  final Room _self;
  final $Res Function(Room) _then;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? floorId = null,Object? name = null,Object? type = null,Object? floor = freezed,Object? devices = null,Object? totalDevices = null,Object? activeDevices = null,Object? todayEnergyKwh = null,}) {
  return _then(Room(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,floorId: null == floorId ? _self.floorId : floorId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RoomType,floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as Floor?,devices: null == devices ? _self.devices : devices // ignore: cast_nullable_to_non_nullable
as List<Device>,totalDevices: null == totalDevices ? _self.totalDevices : totalDevices // ignore: cast_nullable_to_non_nullable
as int,activeDevices: null == activeDevices ? _self.activeDevices : activeDevices // ignore: cast_nullable_to_non_nullable
as int,todayEnergyKwh: null == todayEnergyKwh ? _self.todayEnergyKwh : todayEnergyKwh // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FloorCopyWith<$Res>? get floor {
    if (_self.floor == null) {
    return null;
  }

  return $FloorCopyWith<$Res>(_self.floor!, (value) {
    return _then(_self.copyWith(floor: value));
  });
}
}


/// Adds pattern-matching-related methods to [Room].
extension RoomPatterns on Room {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Room value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Room() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Room value)  $default,){
final _that = this;
switch (_that) {
case _Room():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Room value)?  $default,){
final _that = this;
switch (_that) {
case _Room() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String floorId,  String name, @JsonKey(unknownEnumValue: RoomType.other)  RoomType type,  Floor? floor,  List<Device> devices,  int totalDevices,  int activeDevices,  double todayEnergyKwh)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Room() when $default != null:
return $default(_that.id,_that.floorId,_that.name,_that.type,_that.floor,_that.devices,_that.totalDevices,_that.activeDevices,_that.todayEnergyKwh);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String floorId,  String name, @JsonKey(unknownEnumValue: RoomType.other)  RoomType type,  Floor? floor,  List<Device> devices,  int totalDevices,  int activeDevices,  double todayEnergyKwh)  $default,) {final _that = this;
switch (_that) {
case _Room():
return $default(_that.id,_that.floorId,_that.name,_that.type,_that.floor,_that.devices,_that.totalDevices,_that.activeDevices,_that.todayEnergyKwh);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String floorId,  String name, @JsonKey(unknownEnumValue: RoomType.other)  RoomType type,  Floor? floor,  List<Device> devices,  int totalDevices,  int activeDevices,  double todayEnergyKwh)?  $default,) {final _that = this;
switch (_that) {
case _Room() when $default != null:
return $default(_that.id,_that.floorId,_that.name,_that.type,_that.floor,_that.devices,_that.totalDevices,_that.activeDevices,_that.todayEnergyKwh);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Room implements Room {
  const _Room({required this.id, required this.floorId, required this.name, @JsonKey(unknownEnumValue: RoomType.other) this.type = RoomType.other, this.floor,  List<Device> devices = const <Device>[], this.totalDevices = 0, this.activeDevices = 0, this.todayEnergyKwh = 0}): _devices = devices;
  factory _Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

@override final  String id;
@override final  String floorId;
@override final  String name;
@override@JsonKey(unknownEnumValue: RoomType.other) final  RoomType type;
@override final  Floor? floor;
 final  List<Device> _devices;
@override@JsonKey() List<Device> get devices {
  if (_devices is EqualUnmodifiableListView) return _devices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_devices);
}

@override@JsonKey() final  int totalDevices;
@override@JsonKey() final  int activeDevices;
@override@JsonKey() final  double todayEnergyKwh;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomCopyWith<_Room> get copyWith => __$RoomCopyWithImpl<_Room>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Room&&(identical(other.id, id) || other.id == id)&&(identical(other.floorId, floorId) || other.floorId == floorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.floor, floor) || other.floor == floor)&&const DeepCollectionEquality().equals(other.devices, _devices)&&(identical(other.totalDevices, totalDevices) || other.totalDevices == totalDevices)&&(identical(other.activeDevices, activeDevices) || other.activeDevices == activeDevices)&&(identical(other.todayEnergyKwh, todayEnergyKwh) || other.todayEnergyKwh == todayEnergyKwh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,floorId,name,type,floor,const DeepCollectionEquality().hash(_devices),totalDevices,activeDevices,todayEnergyKwh);
}

@override
String toString() {
    return 'Room(id: $id, floorId: $floorId, name: $name, type: $type, floor: $floor, devices: $devices, totalDevices: $totalDevices, activeDevices: $activeDevices, todayEnergyKwh: $todayEnergyKwh)';
}


}

/// @nodoc
abstract mixin class _$RoomCopyWith<$Res> implements $RoomCopyWith<$Res> {
  factory _$RoomCopyWith(_Room value, $Res Function(_Room) _then) = __$RoomCopyWithImpl;
@override @useResult
$Res call({
 String id, String floorId, String name,@JsonKey(unknownEnumValue: RoomType.other) RoomType type, Floor? floor, List<Device> devices, int totalDevices, int activeDevices, double todayEnergyKwh
});


@override $FloorCopyWith<$Res>? get floor;

}
/// @nodoc
class __$RoomCopyWithImpl<$Res>
    implements _$RoomCopyWith<$Res> {
  __$RoomCopyWithImpl(this._self, this._then);

  final _Room _self;
  final $Res Function(_Room) _then;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? floorId = null,Object? name = null,Object? type = null,Object? floor = freezed,Object? devices = null,Object? totalDevices = null,Object? activeDevices = null,Object? todayEnergyKwh = null,}) {
  return _then(_Room(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,floorId: null == floorId ? _self.floorId : floorId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RoomType,floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as Floor?,devices: null == devices ? _self._devices : devices // ignore: cast_nullable_to_non_nullable
as List<Device>,totalDevices: null == totalDevices ? _self.totalDevices : totalDevices // ignore: cast_nullable_to_non_nullable
as int,activeDevices: null == activeDevices ? _self.activeDevices : activeDevices // ignore: cast_nullable_to_non_nullable
as int,todayEnergyKwh: null == todayEnergyKwh ? _self.todayEnergyKwh : todayEnergyKwh // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FloorCopyWith<$Res>? get floor {
    if (_self.floor == null) {
    return null;
  }

  return $FloorCopyWith<$Res>(_self.floor!, (value) {
    return _then(_self.copyWith(floor: value));
  });
}
}


/// @nodoc
mixin _$Device {

 String get id; String get name; String get roomId;@JsonKey(unknownEnumValue: DeviceType.other) DeviceType get type;@JsonKey(unknownEnumValue: DeviceStatus.off) DeviceStatus get status;/// Alcançável pelo broker MQTT. Offline = controle indisponível.
 bool get online;/// Tópico MQTT base; comandos vão para `{mqttTopic}/command`.
 String? get mqttTopic; Map<String, dynamic>? get metadata; DateTime? get lastSeen; Room? get room;
/// Create a copy of Device
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceCopyWith<Device> get copyWith => _$DeviceCopyWithImpl<Device>(this as Device, _$identity);

  /// Serializes this Device to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Device;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Device&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.roomId, _this.roomId) || other.roomId == _this.roomId)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.online, _this.online) || other.online == _this.online)&&(identical(other.mqttTopic, _this.mqttTopic) || other.mqttTopic == _this.mqttTopic)&&const DeepCollectionEquality().equals(other.metadata, _this.metadata)&&(identical(other.lastSeen, _this.lastSeen) || other.lastSeen == _this.lastSeen)&&(identical(other.room, _this.room) || other.room == _this.room));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Device;
  return Object.hash(runtimeType,_this.id,_this.name,_this.roomId,_this.type,_this.status,_this.online,_this.mqttTopic,const DeepCollectionEquality().hash(_this.metadata),_this.lastSeen,_this.room);
}

@override
String toString() {
  final _this = this as Device;
  return 'Device(id: ${_this.id}, name: ${_this.name}, roomId: ${_this.roomId}, type: ${_this.type}, status: ${_this.status}, online: ${_this.online}, mqttTopic: ${_this.mqttTopic}, metadata: ${_this.metadata}, lastSeen: ${_this.lastSeen}, room: ${_this.room})';
}


}

/// @nodoc
abstract mixin class $DeviceCopyWith<$Res>  {
  factory $DeviceCopyWith(Device value, $Res Function(Device) _then) = _$DeviceCopyWithImpl;
@useResult
$Res call({
 String id, String name, String roomId,@JsonKey(unknownEnumValue: DeviceType.other) DeviceType type,@JsonKey(unknownEnumValue: DeviceStatus.off) DeviceStatus status, bool online, String? mqttTopic, Map<String, dynamic>? metadata, DateTime? lastSeen, Room? room
});


$RoomCopyWith<$Res>? get room;

}
/// @nodoc
class _$DeviceCopyWithImpl<$Res>
    implements $DeviceCopyWith<$Res> {
  _$DeviceCopyWithImpl(this._self, this._then);

  final Device _self;
  final $Res Function(Device) _then;

/// Create a copy of Device
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? roomId = null,Object? type = null,Object? status = null,Object? online = null,Object? mqttTopic = freezed,Object? metadata = freezed,Object? lastSeen = freezed,Object? room = freezed,}) {
  return _then(Device(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DeviceType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeviceStatus,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,mqttTopic: freezed == mqttTopic ? _self.mqttTopic : mqttTopic // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime?,room: freezed == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as Room?,
  ));
}
/// Create a copy of Device
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoomCopyWith<$Res>? get room {
    if (_self.room == null) {
    return null;
  }

  return $RoomCopyWith<$Res>(_self.room!, (value) {
    return _then(_self.copyWith(room: value));
  });
}
}


/// Adds pattern-matching-related methods to [Device].
extension DevicePatterns on Device {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Device value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Device() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Device value)  $default,){
final _that = this;
switch (_that) {
case _Device():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Device value)?  $default,){
final _that = this;
switch (_that) {
case _Device() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String roomId, @JsonKey(unknownEnumValue: DeviceType.other)  DeviceType type, @JsonKey(unknownEnumValue: DeviceStatus.off)  DeviceStatus status,  bool online,  String? mqttTopic,  Map<String, dynamic>? metadata,  DateTime? lastSeen,  Room? room)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Device() when $default != null:
return $default(_that.id,_that.name,_that.roomId,_that.type,_that.status,_that.online,_that.mqttTopic,_that.metadata,_that.lastSeen,_that.room);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String roomId, @JsonKey(unknownEnumValue: DeviceType.other)  DeviceType type, @JsonKey(unknownEnumValue: DeviceStatus.off)  DeviceStatus status,  bool online,  String? mqttTopic,  Map<String, dynamic>? metadata,  DateTime? lastSeen,  Room? room)  $default,) {final _that = this;
switch (_that) {
case _Device():
return $default(_that.id,_that.name,_that.roomId,_that.type,_that.status,_that.online,_that.mqttTopic,_that.metadata,_that.lastSeen,_that.room);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String roomId, @JsonKey(unknownEnumValue: DeviceType.other)  DeviceType type, @JsonKey(unknownEnumValue: DeviceStatus.off)  DeviceStatus status,  bool online,  String? mqttTopic,  Map<String, dynamic>? metadata,  DateTime? lastSeen,  Room? room)?  $default,) {final _that = this;
switch (_that) {
case _Device() when $default != null:
return $default(_that.id,_that.name,_that.roomId,_that.type,_that.status,_that.online,_that.mqttTopic,_that.metadata,_that.lastSeen,_that.room);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Device extends Device {
  const _Device({required this.id, required this.name, required this.roomId, @JsonKey(unknownEnumValue: DeviceType.other) this.type = DeviceType.other, @JsonKey(unknownEnumValue: DeviceStatus.off) this.status = DeviceStatus.off, this.online = false, this.mqttTopic,  Map<String, dynamic>? metadata, this.lastSeen, this.room}): _metadata = metadata,super._();
  factory _Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);

@override final  String id;
@override final  String name;
@override final  String roomId;
@override@JsonKey(unknownEnumValue: DeviceType.other) final  DeviceType type;
@override@JsonKey(unknownEnumValue: DeviceStatus.off) final  DeviceStatus status;
/// Alcançável pelo broker MQTT. Offline = controle indisponível.
@override@JsonKey() final  bool online;
/// Tópico MQTT base; comandos vão para `{mqttTopic}/command`.
@override final  String? mqttTopic;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime? lastSeen;
@override final  Room? room;

/// Create a copy of Device
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceCopyWith<_Device> get copyWith => __$DeviceCopyWithImpl<_Device>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Device&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.online, online) || other.online == online)&&(identical(other.mqttTopic, mqttTopic) || other.mqttTopic == mqttTopic)&&const DeepCollectionEquality().equals(other.metadata, _metadata)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&(identical(other.room, room) || other.room == room));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,roomId,type,status,online,mqttTopic,const DeepCollectionEquality().hash(_metadata),lastSeen,room);
}

@override
String toString() {
    return 'Device(id: $id, name: $name, roomId: $roomId, type: $type, status: $status, online: $online, mqttTopic: $mqttTopic, metadata: $metadata, lastSeen: $lastSeen, room: $room)';
}


}

/// @nodoc
abstract mixin class _$DeviceCopyWith<$Res> implements $DeviceCopyWith<$Res> {
  factory _$DeviceCopyWith(_Device value, $Res Function(_Device) _then) = __$DeviceCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String roomId,@JsonKey(unknownEnumValue: DeviceType.other) DeviceType type,@JsonKey(unknownEnumValue: DeviceStatus.off) DeviceStatus status, bool online, String? mqttTopic, Map<String, dynamic>? metadata, DateTime? lastSeen, Room? room
});


@override $RoomCopyWith<$Res>? get room;

}
/// @nodoc
class __$DeviceCopyWithImpl<$Res>
    implements _$DeviceCopyWith<$Res> {
  __$DeviceCopyWithImpl(this._self, this._then);

  final _Device _self;
  final $Res Function(_Device) _then;

/// Create a copy of Device
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? roomId = null,Object? type = null,Object? status = null,Object? online = null,Object? mqttTopic = freezed,Object? metadata = freezed,Object? lastSeen = freezed,Object? room = freezed,}) {
  return _then(_Device(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DeviceType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeviceStatus,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,mqttTopic: freezed == mqttTopic ? _self.mqttTopic : mqttTopic // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime?,room: freezed == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as Room?,
  ));
}

/// Create a copy of Device
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoomCopyWith<$Res>? get room {
    if (_self.room == null) {
    return null;
  }

  return $RoomCopyWith<$Res>(_self.room!, (value) {
    return _then(_self.copyWith(room: value));
  });
}
}

// dart format on

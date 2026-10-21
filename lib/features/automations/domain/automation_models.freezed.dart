// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'automation_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AutomationAction {

 String? get topic; Map<String, dynamic>? get payload; String? get deviceId; String? get deviceName; DeviceAction? get command;
/// Create a copy of AutomationAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutomationActionCopyWith<AutomationAction> get copyWith => _$AutomationActionCopyWithImpl<AutomationAction>(this as AutomationAction, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AutomationAction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutomationAction&&(identical(other.topic, _this.topic) || other.topic == _this.topic)&&const DeepCollectionEquality().equals(other.payload, _this.payload)&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&(identical(other.deviceName, _this.deviceName) || other.deviceName == _this.deviceName)&&(identical(other.command, _this.command) || other.command == _this.command));
}


@override
int get hashCode {
  final _this = this as AutomationAction;
  return Object.hash(runtimeType,_this.topic,const DeepCollectionEquality().hash(_this.payload),_this.deviceId,_this.deviceName,_this.command);
}

@override
String toString() {
  final _this = this as AutomationAction;
  return 'AutomationAction(topic: ${_this.topic}, payload: ${_this.payload}, deviceId: ${_this.deviceId}, deviceName: ${_this.deviceName}, command: ${_this.command})';
}


}

/// @nodoc
abstract mixin class $AutomationActionCopyWith<$Res>  {
  factory $AutomationActionCopyWith(AutomationAction value, $Res Function(AutomationAction) _then) = _$AutomationActionCopyWithImpl;
@useResult
$Res call({
 String? topic, Map<String, dynamic>? payload, String? deviceId, String? deviceName, DeviceAction? command
});




}
/// @nodoc
class _$AutomationActionCopyWithImpl<$Res>
    implements $AutomationActionCopyWith<$Res> {
  _$AutomationActionCopyWithImpl(this._self, this._then);

  final AutomationAction _self;
  final $Res Function(AutomationAction) _then;

/// Create a copy of AutomationAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? topic = freezed,Object? payload = freezed,Object? deviceId = freezed,Object? deviceName = freezed,Object? command = freezed,}) {
  return _then(AutomationAction(
topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,deviceId: freezed == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String?,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,command: freezed == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as DeviceAction?,
  ));
}

}


/// Adds pattern-matching-related methods to [AutomationAction].
extension AutomationActionPatterns on AutomationAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutomationAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutomationAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutomationAction value)  $default,){
final _that = this;
switch (_that) {
case _AutomationAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutomationAction value)?  $default,){
final _that = this;
switch (_that) {
case _AutomationAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? topic,  Map<String, dynamic>? payload,  String? deviceId,  String? deviceName,  DeviceAction? command)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutomationAction() when $default != null:
return $default(_that.topic,_that.payload,_that.deviceId,_that.deviceName,_that.command);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? topic,  Map<String, dynamic>? payload,  String? deviceId,  String? deviceName,  DeviceAction? command)  $default,) {final _that = this;
switch (_that) {
case _AutomationAction():
return $default(_that.topic,_that.payload,_that.deviceId,_that.deviceName,_that.command);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? topic,  Map<String, dynamic>? payload,  String? deviceId,  String? deviceName,  DeviceAction? command)?  $default,) {final _that = this;
switch (_that) {
case _AutomationAction() when $default != null:
return $default(_that.topic,_that.payload,_that.deviceId,_that.deviceName,_that.command);case _:
  return null;

}
}

}

/// @nodoc


class _AutomationAction extends AutomationAction {
  const _AutomationAction({this.topic,  Map<String, dynamic>? payload, this.deviceId, this.deviceName, this.command}): _payload = payload,super._();
  

@override final  String? topic;
 final  Map<String, dynamic>? _payload;
@override Map<String, dynamic>? get payload {
  final value = _payload;
  if (value == null) return null;
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? deviceId;
@override final  String? deviceName;
@override final  DeviceAction? command;

/// Create a copy of AutomationAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutomationActionCopyWith<_AutomationAction> get copyWith => __$AutomationActionCopyWithImpl<_AutomationAction>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutomationAction&&(identical(other.topic, topic) || other.topic == topic)&&const DeepCollectionEquality().equals(other.payload, _payload)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.command, command) || other.command == command));
}


@override
int get hashCode {
    return Object.hash(runtimeType,topic,const DeepCollectionEquality().hash(_payload),deviceId,deviceName,command);
}

@override
String toString() {
    return 'AutomationAction(topic: $topic, payload: $payload, deviceId: $deviceId, deviceName: $deviceName, command: $command)';
}


}

/// @nodoc
abstract mixin class _$AutomationActionCopyWith<$Res> implements $AutomationActionCopyWith<$Res> {
  factory _$AutomationActionCopyWith(_AutomationAction value, $Res Function(_AutomationAction) _then) = __$AutomationActionCopyWithImpl;
@override @useResult
$Res call({
 String? topic, Map<String, dynamic>? payload, String? deviceId, String? deviceName, DeviceAction? command
});




}
/// @nodoc
class __$AutomationActionCopyWithImpl<$Res>
    implements _$AutomationActionCopyWith<$Res> {
  __$AutomationActionCopyWithImpl(this._self, this._then);

  final _AutomationAction _self;
  final $Res Function(_AutomationAction) _then;

/// Create a copy of AutomationAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? topic = freezed,Object? payload = freezed,Object? deviceId = freezed,Object? deviceName = freezed,Object? command = freezed,}) {
  return _then(_AutomationAction(
topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,payload: freezed == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,deviceId: freezed == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String?,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,command: freezed == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as DeviceAction?,
  ));
}


}


/// @nodoc
mixin _$Automation {

 String get id; String get name; String? get description;@JsonKey(unknownEnumValue: TriggerType.manual) TriggerType get triggerType; String? get cron; String? get condition;@JsonKey(fromJson: AutomationAction.parse, toJson: _actionToJson) AutomationAction get action; bool get enabled; DateTime? get lastRunAt; DateTime? get createdAt;@JsonKey(readValue: _readCreatorName) String? get creatorName;
/// Create a copy of Automation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutomationCopyWith<Automation> get copyWith => _$AutomationCopyWithImpl<Automation>(this as Automation, _$identity);

  /// Serializes this Automation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Automation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Automation&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.triggerType, _this.triggerType) || other.triggerType == _this.triggerType)&&(identical(other.cron, _this.cron) || other.cron == _this.cron)&&(identical(other.condition, _this.condition) || other.condition == _this.condition)&&(identical(other.action, _this.action) || other.action == _this.action)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.lastRunAt, _this.lastRunAt) || other.lastRunAt == _this.lastRunAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.creatorName, _this.creatorName) || other.creatorName == _this.creatorName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Automation;
  return Object.hash(runtimeType,_this.id,_this.name,_this.description,_this.triggerType,_this.cron,_this.condition,_this.action,_this.enabled,_this.lastRunAt,_this.createdAt,_this.creatorName);
}

@override
String toString() {
  final _this = this as Automation;
  return 'Automation(id: ${_this.id}, name: ${_this.name}, description: ${_this.description}, triggerType: ${_this.triggerType}, cron: ${_this.cron}, condition: ${_this.condition}, action: ${_this.action}, enabled: ${_this.enabled}, lastRunAt: ${_this.lastRunAt}, createdAt: ${_this.createdAt}, creatorName: ${_this.creatorName})';
}


}

/// @nodoc
abstract mixin class $AutomationCopyWith<$Res>  {
  factory $AutomationCopyWith(Automation value, $Res Function(Automation) _then) = _$AutomationCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description,@JsonKey(unknownEnumValue: TriggerType.manual) TriggerType triggerType, String? cron, String? condition,@JsonKey(fromJson: AutomationAction.parse, toJson: _actionToJson) AutomationAction action, bool enabled, DateTime? lastRunAt, DateTime? createdAt,@JsonKey(readValue: _readCreatorName) String? creatorName
});


$AutomationActionCopyWith<$Res> get action;

}
/// @nodoc
class _$AutomationCopyWithImpl<$Res>
    implements $AutomationCopyWith<$Res> {
  _$AutomationCopyWithImpl(this._self, this._then);

  final Automation _self;
  final $Res Function(Automation) _then;

/// Create a copy of Automation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? triggerType = null,Object? cron = freezed,Object? condition = freezed,Object? action = null,Object? enabled = null,Object? lastRunAt = freezed,Object? createdAt = freezed,Object? creatorName = freezed,}) {
  return _then(Automation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,triggerType: null == triggerType ? _self.triggerType : triggerType // ignore: cast_nullable_to_non_nullable
as TriggerType,cron: freezed == cron ? _self.cron : cron // ignore: cast_nullable_to_non_nullable
as String?,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String?,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as AutomationAction,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,lastRunAt: freezed == lastRunAt ? _self.lastRunAt : lastRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,creatorName: freezed == creatorName ? _self.creatorName : creatorName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Automation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutomationActionCopyWith<$Res> get action {
  
  return $AutomationActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}


/// Adds pattern-matching-related methods to [Automation].
extension AutomationPatterns on Automation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Automation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Automation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Automation value)  $default,){
final _that = this;
switch (_that) {
case _Automation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Automation value)?  $default,){
final _that = this;
switch (_that) {
case _Automation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description, @JsonKey(unknownEnumValue: TriggerType.manual)  TriggerType triggerType,  String? cron,  String? condition, @JsonKey(fromJson: AutomationAction.parse, toJson: _actionToJson)  AutomationAction action,  bool enabled,  DateTime? lastRunAt,  DateTime? createdAt, @JsonKey(readValue: _readCreatorName)  String? creatorName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Automation() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.triggerType,_that.cron,_that.condition,_that.action,_that.enabled,_that.lastRunAt,_that.createdAt,_that.creatorName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description, @JsonKey(unknownEnumValue: TriggerType.manual)  TriggerType triggerType,  String? cron,  String? condition, @JsonKey(fromJson: AutomationAction.parse, toJson: _actionToJson)  AutomationAction action,  bool enabled,  DateTime? lastRunAt,  DateTime? createdAt, @JsonKey(readValue: _readCreatorName)  String? creatorName)  $default,) {final _that = this;
switch (_that) {
case _Automation():
return $default(_that.id,_that.name,_that.description,_that.triggerType,_that.cron,_that.condition,_that.action,_that.enabled,_that.lastRunAt,_that.createdAt,_that.creatorName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description, @JsonKey(unknownEnumValue: TriggerType.manual)  TriggerType triggerType,  String? cron,  String? condition, @JsonKey(fromJson: AutomationAction.parse, toJson: _actionToJson)  AutomationAction action,  bool enabled,  DateTime? lastRunAt,  DateTime? createdAt, @JsonKey(readValue: _readCreatorName)  String? creatorName)?  $default,) {final _that = this;
switch (_that) {
case _Automation() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.triggerType,_that.cron,_that.condition,_that.action,_that.enabled,_that.lastRunAt,_that.createdAt,_that.creatorName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Automation extends Automation {
  const _Automation({required this.id, required this.name, this.description, @JsonKey(unknownEnumValue: TriggerType.manual) this.triggerType = TriggerType.manual, this.cron, this.condition, @JsonKey(fromJson: AutomationAction.parse, toJson: _actionToJson) this.action = const AutomationAction(), this.enabled = true, this.lastRunAt, this.createdAt, @JsonKey(readValue: _readCreatorName) this.creatorName}): super._();
  factory _Automation.fromJson(Map<String, dynamic> json) => _$AutomationFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? description;
@override@JsonKey(unknownEnumValue: TriggerType.manual) final  TriggerType triggerType;
@override final  String? cron;
@override final  String? condition;
@override@JsonKey(fromJson: AutomationAction.parse, toJson: _actionToJson) final  AutomationAction action;
@override@JsonKey() final  bool enabled;
@override final  DateTime? lastRunAt;
@override final  DateTime? createdAt;
@override@JsonKey(readValue: _readCreatorName) final  String? creatorName;

/// Create a copy of Automation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutomationCopyWith<_Automation> get copyWith => __$AutomationCopyWithImpl<_Automation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AutomationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Automation&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.triggerType, triggerType) || other.triggerType == triggerType)&&(identical(other.cron, cron) || other.cron == cron)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.action, action) || other.action == action)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.lastRunAt, lastRunAt) || other.lastRunAt == lastRunAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.creatorName, creatorName) || other.creatorName == creatorName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,description,triggerType,cron,condition,action,enabled,lastRunAt,createdAt,creatorName);
}

@override
String toString() {
    return 'Automation(id: $id, name: $name, description: $description, triggerType: $triggerType, cron: $cron, condition: $condition, action: $action, enabled: $enabled, lastRunAt: $lastRunAt, createdAt: $createdAt, creatorName: $creatorName)';
}


}

/// @nodoc
abstract mixin class _$AutomationCopyWith<$Res> implements $AutomationCopyWith<$Res> {
  factory _$AutomationCopyWith(_Automation value, $Res Function(_Automation) _then) = __$AutomationCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description,@JsonKey(unknownEnumValue: TriggerType.manual) TriggerType triggerType, String? cron, String? condition,@JsonKey(fromJson: AutomationAction.parse, toJson: _actionToJson) AutomationAction action, bool enabled, DateTime? lastRunAt, DateTime? createdAt,@JsonKey(readValue: _readCreatorName) String? creatorName
});


@override $AutomationActionCopyWith<$Res> get action;

}
/// @nodoc
class __$AutomationCopyWithImpl<$Res>
    implements _$AutomationCopyWith<$Res> {
  __$AutomationCopyWithImpl(this._self, this._then);

  final _Automation _self;
  final $Res Function(_Automation) _then;

/// Create a copy of Automation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? triggerType = null,Object? cron = freezed,Object? condition = freezed,Object? action = null,Object? enabled = null,Object? lastRunAt = freezed,Object? createdAt = freezed,Object? creatorName = freezed,}) {
  return _then(_Automation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,triggerType: null == triggerType ? _self.triggerType : triggerType // ignore: cast_nullable_to_non_nullable
as TriggerType,cron: freezed == cron ? _self.cron : cron // ignore: cast_nullable_to_non_nullable
as String?,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String?,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as AutomationAction,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,lastRunAt: freezed == lastRunAt ? _self.lastRunAt : lastRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,creatorName: freezed == creatorName ? _self.creatorName : creatorName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Automation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutomationActionCopyWith<$Res> get action {
  
  return $AutomationActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}


/// @nodoc
mixin _$AutomationRun {

 String get id; DateTime get runAt; bool get success; String? get logs;
/// Create a copy of AutomationRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutomationRunCopyWith<AutomationRun> get copyWith => _$AutomationRunCopyWithImpl<AutomationRun>(this as AutomationRun, _$identity);

  /// Serializes this AutomationRun to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AutomationRun;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutomationRun&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.runAt, _this.runAt) || other.runAt == _this.runAt)&&(identical(other.success, _this.success) || other.success == _this.success)&&(identical(other.logs, _this.logs) || other.logs == _this.logs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AutomationRun;
  return Object.hash(runtimeType,_this.id,_this.runAt,_this.success,_this.logs);
}

@override
String toString() {
  final _this = this as AutomationRun;
  return 'AutomationRun(id: ${_this.id}, runAt: ${_this.runAt}, success: ${_this.success}, logs: ${_this.logs})';
}


}

/// @nodoc
abstract mixin class $AutomationRunCopyWith<$Res>  {
  factory $AutomationRunCopyWith(AutomationRun value, $Res Function(AutomationRun) _then) = _$AutomationRunCopyWithImpl;
@useResult
$Res call({
 String id, DateTime runAt, bool success, String? logs
});




}
/// @nodoc
class _$AutomationRunCopyWithImpl<$Res>
    implements $AutomationRunCopyWith<$Res> {
  _$AutomationRunCopyWithImpl(this._self, this._then);

  final AutomationRun _self;
  final $Res Function(AutomationRun) _then;

/// Create a copy of AutomationRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? runAt = null,Object? success = null,Object? logs = freezed,}) {
  return _then(AutomationRun(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,runAt: null == runAt ? _self.runAt : runAt // ignore: cast_nullable_to_non_nullable
as DateTime,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,logs: freezed == logs ? _self.logs : logs // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AutomationRun].
extension AutomationRunPatterns on AutomationRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutomationRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutomationRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutomationRun value)  $default,){
final _that = this;
switch (_that) {
case _AutomationRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutomationRun value)?  $default,){
final _that = this;
switch (_that) {
case _AutomationRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime runAt,  bool success,  String? logs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutomationRun() when $default != null:
return $default(_that.id,_that.runAt,_that.success,_that.logs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime runAt,  bool success,  String? logs)  $default,) {final _that = this;
switch (_that) {
case _AutomationRun():
return $default(_that.id,_that.runAt,_that.success,_that.logs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime runAt,  bool success,  String? logs)?  $default,) {final _that = this;
switch (_that) {
case _AutomationRun() when $default != null:
return $default(_that.id,_that.runAt,_that.success,_that.logs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AutomationRun implements AutomationRun {
  const _AutomationRun({required this.id, required this.runAt, this.success = false, this.logs});
  factory _AutomationRun.fromJson(Map<String, dynamic> json) => _$AutomationRunFromJson(json);

@override final  String id;
@override final  DateTime runAt;
@override@JsonKey() final  bool success;
@override final  String? logs;

/// Create a copy of AutomationRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutomationRunCopyWith<_AutomationRun> get copyWith => __$AutomationRunCopyWithImpl<_AutomationRun>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AutomationRunToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutomationRun&&(identical(other.id, id) || other.id == id)&&(identical(other.runAt, runAt) || other.runAt == runAt)&&(identical(other.success, success) || other.success == success)&&(identical(other.logs, logs) || other.logs == logs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,runAt,success,logs);
}

@override
String toString() {
    return 'AutomationRun(id: $id, runAt: $runAt, success: $success, logs: $logs)';
}


}

/// @nodoc
abstract mixin class _$AutomationRunCopyWith<$Res> implements $AutomationRunCopyWith<$Res> {
  factory _$AutomationRunCopyWith(_AutomationRun value, $Res Function(_AutomationRun) _then) = __$AutomationRunCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime runAt, bool success, String? logs
});




}
/// @nodoc
class __$AutomationRunCopyWithImpl<$Res>
    implements _$AutomationRunCopyWith<$Res> {
  __$AutomationRunCopyWithImpl(this._self, this._then);

  final _AutomationRun _self;
  final $Res Function(_AutomationRun) _then;

/// Create a copy of AutomationRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? runAt = null,Object? success = null,Object? logs = freezed,}) {
  return _then(_AutomationRun(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,runAt: null == runAt ? _self.runAt : runAt // ignore: cast_nullable_to_non_nullable
as DateTime,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,logs: freezed == logs ? _self.logs : logs // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

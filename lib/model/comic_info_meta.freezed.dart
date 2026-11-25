// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_info_meta.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ComicInfoActionItem {

@JsonKey(name: 'name') String get name;@JsonKey(name: 'onTap') Map<String, dynamic> get onTap;@JsonKey(name: 'onLongPress') String? get onLongPress;@JsonKey(name: 'extern') Map<String, dynamic> get extern;
/// Create a copy of ComicInfoActionItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicInfoActionItemCopyWith<ComicInfoActionItem> get copyWith => _$ComicInfoActionItemCopyWithImpl<ComicInfoActionItem>(this as ComicInfoActionItem, _$identity);

  /// Serializes this ComicInfoActionItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ComicInfoActionItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicInfoActionItem&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.onTap, _this.onTap)&&(identical(other.onLongPress, _this.onLongPress) || other.onLongPress == _this.onLongPress)&&const DeepCollectionEquality().equals(other.extern, _this.extern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ComicInfoActionItem;
  return Object.hash(runtimeType,_this.name,const DeepCollectionEquality().hash(_this.onTap),_this.onLongPress,const DeepCollectionEquality().hash(_this.extern));
}

@override
String toString() {
  final _this = this as ComicInfoActionItem;
  return 'ComicInfoActionItem(name: ${_this.name}, onTap: ${_this.onTap}, onLongPress: ${_this.onLongPress}, extern: ${_this.extern})';
}


}

/// @nodoc
abstract mixin class $ComicInfoActionItemCopyWith<$Res>  {
  factory $ComicInfoActionItemCopyWith(ComicInfoActionItem value, $Res Function(ComicInfoActionItem) _then) = _$ComicInfoActionItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'name') String name,@JsonKey(name: 'onTap') Map<String, dynamic> onTap,@JsonKey(name: 'onLongPress') String? onLongPress,@JsonKey(name: 'extern') Map<String, dynamic> extern
});




}
/// @nodoc
class _$ComicInfoActionItemCopyWithImpl<$Res>
    implements $ComicInfoActionItemCopyWith<$Res> {
  _$ComicInfoActionItemCopyWithImpl(this._self, this._then);

  final ComicInfoActionItem _self;
  final $Res Function(ComicInfoActionItem) _then;

/// Create a copy of ComicInfoActionItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? onTap = null,Object? onLongPress = freezed,Object? extern = null,}) {
  return _then(ComicInfoActionItem(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,onTap: null == onTap ? _self.onTap : onTap // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,onLongPress: freezed == onLongPress ? _self.onLongPress : onLongPress // ignore: cast_nullable_to_non_nullable
as String?,extern: null == extern ? _self.extern : extern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicInfoActionItem].
extension ComicInfoActionItemPatterns on ComicInfoActionItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicInfoActionItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicInfoActionItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicInfoActionItem value)  $default,){
final _that = this;
switch (_that) {
case _ComicInfoActionItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicInfoActionItem value)?  $default,){
final _that = this;
switch (_that) {
case _ComicInfoActionItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'name')  String name, @JsonKey(name: 'onTap')  Map<String, dynamic> onTap, @JsonKey(name: 'onLongPress')  String? onLongPress, @JsonKey(name: 'extern')  Map<String, dynamic> extern)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicInfoActionItem() when $default != null:
return $default(_that.name,_that.onTap,_that.onLongPress,_that.extern);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'name')  String name, @JsonKey(name: 'onTap')  Map<String, dynamic> onTap, @JsonKey(name: 'onLongPress')  String? onLongPress, @JsonKey(name: 'extern')  Map<String, dynamic> extern)  $default,) {final _that = this;
switch (_that) {
case _ComicInfoActionItem():
return $default(_that.name,_that.onTap,_that.onLongPress,_that.extern);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'name')  String name, @JsonKey(name: 'onTap')  Map<String, dynamic> onTap, @JsonKey(name: 'onLongPress')  String? onLongPress, @JsonKey(name: 'extern')  Map<String, dynamic> extern)?  $default,) {final _that = this;
switch (_that) {
case _ComicInfoActionItem() when $default != null:
return $default(_that.name,_that.onTap,_that.onLongPress,_that.extern);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicInfoActionItem implements ComicInfoActionItem {
  const _ComicInfoActionItem({@JsonKey(name: 'name') required this.name, @JsonKey(name: 'onTap')  Map<String, dynamic> onTap = const {}, @JsonKey(name: 'onLongPress') this.onLongPress, @JsonKey(name: 'extern')  Map<String, dynamic> extern = const {}}): _onTap = onTap,_extern = extern;
  factory _ComicInfoActionItem.fromJson(Map<String, dynamic> json) => _$ComicInfoActionItemFromJson(json);

@override@JsonKey(name: 'name') final  String name;
 final  Map<String, dynamic> _onTap;
@override@JsonKey(name: 'onTap') Map<String, dynamic> get onTap {
  if (_onTap is EqualUnmodifiableMapView) return _onTap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_onTap);
}

@override@JsonKey(name: 'onLongPress') final  String? onLongPress;
 final  Map<String, dynamic> _extern;
@override@JsonKey(name: 'extern') Map<String, dynamic> get extern {
  if (_extern is EqualUnmodifiableMapView) return _extern;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extern);
}


/// Create a copy of ComicInfoActionItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicInfoActionItemCopyWith<_ComicInfoActionItem> get copyWith => __$ComicInfoActionItemCopyWithImpl<_ComicInfoActionItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicInfoActionItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicInfoActionItem&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.onTap, _onTap)&&(identical(other.onLongPress, onLongPress) || other.onLongPress == onLongPress)&&const DeepCollectionEquality().equals(other.extern, _extern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_onTap),onLongPress,const DeepCollectionEquality().hash(_extern));
}

@override
String toString() {
    return 'ComicInfoActionItem(name: $name, onTap: $onTap, onLongPress: $onLongPress, extern: $extern)';
}


}

/// @nodoc
abstract mixin class _$ComicInfoActionItemCopyWith<$Res> implements $ComicInfoActionItemCopyWith<$Res> {
  factory _$ComicInfoActionItemCopyWith(_ComicInfoActionItem value, $Res Function(_ComicInfoActionItem) _then) = __$ComicInfoActionItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'name') String name,@JsonKey(name: 'onTap') Map<String, dynamic> onTap,@JsonKey(name: 'onLongPress') String? onLongPress,@JsonKey(name: 'extern') Map<String, dynamic> extern
});




}
/// @nodoc
class __$ComicInfoActionItemCopyWithImpl<$Res>
    implements _$ComicInfoActionItemCopyWith<$Res> {
  __$ComicInfoActionItemCopyWithImpl(this._self, this._then);

  final _ComicInfoActionItem _self;
  final $Res Function(_ComicInfoActionItem) _then;

/// Create a copy of ComicInfoActionItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? onTap = null,Object? onLongPress = freezed,Object? extern = null,}) {
  return _then(_ComicInfoActionItem(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,onTap: null == onTap ? _self._onTap : onTap // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,onLongPress: freezed == onLongPress ? _self.onLongPress : onLongPress // ignore: cast_nullable_to_non_nullable
as String?,extern: null == extern ? _self._extern : extern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$ComicInfoMetadata {

@JsonKey(name: 'type') String get type;@JsonKey(name: 'name') String get name;@JsonKey(name: 'value') List<ComicInfoActionItem> get value;
/// Create a copy of ComicInfoMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicInfoMetadataCopyWith<ComicInfoMetadata> get copyWith => _$ComicInfoMetadataCopyWithImpl<ComicInfoMetadata>(this as ComicInfoMetadata, _$identity);

  /// Serializes this ComicInfoMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ComicInfoMetadata;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicInfoMetadata&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.value, _this.value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ComicInfoMetadata;
  return Object.hash(runtimeType,_this.type,_this.name,const DeepCollectionEquality().hash(_this.value));
}

@override
String toString() {
  final _this = this as ComicInfoMetadata;
  return 'ComicInfoMetadata(type: ${_this.type}, name: ${_this.name}, value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $ComicInfoMetadataCopyWith<$Res>  {
  factory $ComicInfoMetadataCopyWith(ComicInfoMetadata value, $Res Function(ComicInfoMetadata) _then) = _$ComicInfoMetadataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'type') String type,@JsonKey(name: 'name') String name,@JsonKey(name: 'value') List<ComicInfoActionItem> value
});




}
/// @nodoc
class _$ComicInfoMetadataCopyWithImpl<$Res>
    implements $ComicInfoMetadataCopyWith<$Res> {
  _$ComicInfoMetadataCopyWithImpl(this._self, this._then);

  final ComicInfoMetadata _self;
  final $Res Function(ComicInfoMetadata) _then;

/// Create a copy of ComicInfoMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? name = null,Object? value = null,}) {
  return _then(ComicInfoMetadata(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as List<ComicInfoActionItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicInfoMetadata].
extension ComicInfoMetadataPatterns on ComicInfoMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicInfoMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicInfoMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicInfoMetadata value)  $default,){
final _that = this;
switch (_that) {
case _ComicInfoMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicInfoMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _ComicInfoMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'type')  String type, @JsonKey(name: 'name')  String name, @JsonKey(name: 'value')  List<ComicInfoActionItem> value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicInfoMetadata() when $default != null:
return $default(_that.type,_that.name,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'type')  String type, @JsonKey(name: 'name')  String name, @JsonKey(name: 'value')  List<ComicInfoActionItem> value)  $default,) {final _that = this;
switch (_that) {
case _ComicInfoMetadata():
return $default(_that.type,_that.name,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'type')  String type, @JsonKey(name: 'name')  String name, @JsonKey(name: 'value')  List<ComicInfoActionItem> value)?  $default,) {final _that = this;
switch (_that) {
case _ComicInfoMetadata() when $default != null:
return $default(_that.type,_that.name,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicInfoMetadata implements ComicInfoMetadata {
  const _ComicInfoMetadata({@JsonKey(name: 'type') required this.type, @JsonKey(name: 'name') required this.name, @JsonKey(name: 'value') required  List<ComicInfoActionItem> value}): _value = value;
  factory _ComicInfoMetadata.fromJson(Map<String, dynamic> json) => _$ComicInfoMetadataFromJson(json);

@override@JsonKey(name: 'type') final  String type;
@override@JsonKey(name: 'name') final  String name;
 final  List<ComicInfoActionItem> _value;
@override@JsonKey(name: 'value') List<ComicInfoActionItem> get value {
  if (_value is EqualUnmodifiableListView) return _value;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_value);
}


/// Create a copy of ComicInfoMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicInfoMetadataCopyWith<_ComicInfoMetadata> get copyWith => __$ComicInfoMetadataCopyWithImpl<_ComicInfoMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicInfoMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicInfoMetadata&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.value, _value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,name,const DeepCollectionEquality().hash(_value));
}

@override
String toString() {
    return 'ComicInfoMetadata(type: $type, name: $name, value: $value)';
}


}

/// @nodoc
abstract mixin class _$ComicInfoMetadataCopyWith<$Res> implements $ComicInfoMetadataCopyWith<$Res> {
  factory _$ComicInfoMetadataCopyWith(_ComicInfoMetadata value, $Res Function(_ComicInfoMetadata) _then) = __$ComicInfoMetadataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'type') String type,@JsonKey(name: 'name') String name,@JsonKey(name: 'value') List<ComicInfoActionItem> value
});




}
/// @nodoc
class __$ComicInfoMetadataCopyWithImpl<$Res>
    implements _$ComicInfoMetadataCopyWith<$Res> {
  __$ComicInfoMetadataCopyWithImpl(this._self, this._then);

  final _ComicInfoMetadata _self;
  final $Res Function(_ComicInfoMetadata) _then;

/// Create a copy of ComicInfoMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? name = null,Object? value = null,}) {
  return _then(_ComicInfoMetadata(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self._value : value // ignore: cast_nullable_to_non_nullable
as List<ComicInfoActionItem>,
  ));
}


}


/// @nodoc
mixin _$ComicImage {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'url') String get url;@JsonKey(name: 'name') String get name;@JsonKey(name: 'path') String get path;@JsonKey(name: 'extern') Map<String, dynamic> get extern;
/// Create a copy of ComicImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicImageCopyWith<ComicImage> get copyWith => _$ComicImageCopyWithImpl<ComicImage>(this as ComicImage, _$identity);

  /// Serializes this ComicImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ComicImage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicImage&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.path, _this.path) || other.path == _this.path)&&const DeepCollectionEquality().equals(other.extern, _this.extern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ComicImage;
  return Object.hash(runtimeType,_this.id,_this.url,_this.name,_this.path,const DeepCollectionEquality().hash(_this.extern));
}

@override
String toString() {
  final _this = this as ComicImage;
  return 'ComicImage(id: ${_this.id}, url: ${_this.url}, name: ${_this.name}, path: ${_this.path}, extern: ${_this.extern})';
}


}

/// @nodoc
abstract mixin class $ComicImageCopyWith<$Res>  {
  factory $ComicImageCopyWith(ComicImage value, $Res Function(ComicImage) _then) = _$ComicImageCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'url') String url,@JsonKey(name: 'name') String name,@JsonKey(name: 'path') String path,@JsonKey(name: 'extern') Map<String, dynamic> extern
});




}
/// @nodoc
class _$ComicImageCopyWithImpl<$Res>
    implements $ComicImageCopyWith<$Res> {
  _$ComicImageCopyWithImpl(this._self, this._then);

  final ComicImage _self;
  final $Res Function(ComicImage) _then;

/// Create a copy of ComicImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? url = null,Object? name = null,Object? path = null,Object? extern = null,}) {
  return _then(ComicImage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,extern: null == extern ? _self.extern : extern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicImage].
extension ComicImagePatterns on ComicImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicImage value)  $default,){
final _that = this;
switch (_that) {
case _ComicImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicImage value)?  $default,){
final _that = this;
switch (_that) {
case _ComicImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'url')  String url, @JsonKey(name: 'name')  String name, @JsonKey(name: 'path')  String path, @JsonKey(name: 'extern')  Map<String, dynamic> extern)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicImage() when $default != null:
return $default(_that.id,_that.url,_that.name,_that.path,_that.extern);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'url')  String url, @JsonKey(name: 'name')  String name, @JsonKey(name: 'path')  String path, @JsonKey(name: 'extern')  Map<String, dynamic> extern)  $default,) {final _that = this;
switch (_that) {
case _ComicImage():
return $default(_that.id,_that.url,_that.name,_that.path,_that.extern);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'url')  String url, @JsonKey(name: 'name')  String name, @JsonKey(name: 'path')  String path, @JsonKey(name: 'extern')  Map<String, dynamic> extern)?  $default,) {final _that = this;
switch (_that) {
case _ComicImage() when $default != null:
return $default(_that.id,_that.url,_that.name,_that.path,_that.extern);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicImage implements ComicImage {
  const _ComicImage({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'url') required this.url, @JsonKey(name: 'name') required this.name, @JsonKey(name: 'path') this.path = '', @JsonKey(name: 'extern')  Map<String, dynamic> extern = const {}}): _extern = extern;
  factory _ComicImage.fromJson(Map<String, dynamic> json) => _$ComicImageFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'url') final  String url;
@override@JsonKey(name: 'name') final  String name;
@override@JsonKey(name: 'path') final  String path;
 final  Map<String, dynamic> _extern;
@override@JsonKey(name: 'extern') Map<String, dynamic> get extern {
  if (_extern is EqualUnmodifiableMapView) return _extern;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extern);
}


/// Create a copy of ComicImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicImageCopyWith<_ComicImage> get copyWith => __$ComicImageCopyWithImpl<_ComicImage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicImageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&const DeepCollectionEquality().equals(other.extern, _extern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,url,name,path,const DeepCollectionEquality().hash(_extern));
}

@override
String toString() {
    return 'ComicImage(id: $id, url: $url, name: $name, path: $path, extern: $extern)';
}


}

/// @nodoc
abstract mixin class _$ComicImageCopyWith<$Res> implements $ComicImageCopyWith<$Res> {
  factory _$ComicImageCopyWith(_ComicImage value, $Res Function(_ComicImage) _then) = __$ComicImageCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'url') String url,@JsonKey(name: 'name') String name,@JsonKey(name: 'path') String path,@JsonKey(name: 'extern') Map<String, dynamic> extern
});




}
/// @nodoc
class __$ComicImageCopyWithImpl<$Res>
    implements _$ComicImageCopyWith<$Res> {
  __$ComicImageCopyWithImpl(this._self, this._then);

  final _ComicImage _self;
  final $Res Function(_ComicImage) _then;

/// Create a copy of ComicImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? url = null,Object? name = null,Object? path = null,Object? extern = null,}) {
  return _then(_ComicImage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,extern: null == extern ? _self._extern : extern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$Creator {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'name') String get name;@JsonKey(name: 'avatar') ComicImage get avatar;@JsonKey(name: 'onTap') Map<String, dynamic> get onTap;@JsonKey(name: 'extern') Map<String, dynamic> get extern;
/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatorCopyWith<Creator> get copyWith => _$CreatorCopyWithImpl<Creator>(this as Creator, _$identity);

  /// Serializes this Creator to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Creator;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Creator&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.avatar, _this.avatar) || other.avatar == _this.avatar)&&const DeepCollectionEquality().equals(other.onTap, _this.onTap)&&const DeepCollectionEquality().equals(other.extern, _this.extern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Creator;
  return Object.hash(runtimeType,_this.id,_this.name,_this.avatar,const DeepCollectionEquality().hash(_this.onTap),const DeepCollectionEquality().hash(_this.extern));
}

@override
String toString() {
  final _this = this as Creator;
  return 'Creator(id: ${_this.id}, name: ${_this.name}, avatar: ${_this.avatar}, onTap: ${_this.onTap}, extern: ${_this.extern})';
}


}

/// @nodoc
abstract mixin class $CreatorCopyWith<$Res>  {
  factory $CreatorCopyWith(Creator value, $Res Function(Creator) _then) = _$CreatorCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'name') String name,@JsonKey(name: 'avatar') ComicImage avatar,@JsonKey(name: 'onTap') Map<String, dynamic> onTap,@JsonKey(name: 'extern') Map<String, dynamic> extern
});


$ComicImageCopyWith<$Res> get avatar;

}
/// @nodoc
class _$CreatorCopyWithImpl<$Res>
    implements $CreatorCopyWith<$Res> {
  _$CreatorCopyWithImpl(this._self, this._then);

  final Creator _self;
  final $Res Function(Creator) _then;

/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? avatar = null,Object? onTap = null,Object? extern = null,}) {
  return _then(Creator(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as ComicImage,onTap: null == onTap ? _self.onTap : onTap // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,extern: null == extern ? _self.extern : extern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}
/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicImageCopyWith<$Res> get avatar {
  
  return $ComicImageCopyWith<$Res>(_self.avatar, (value) {
    return _then(_self.copyWith(avatar: value));
  });
}
}


/// Adds pattern-matching-related methods to [Creator].
extension CreatorPatterns on Creator {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Creator value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Creator() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Creator value)  $default,){
final _that = this;
switch (_that) {
case _Creator():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Creator value)?  $default,){
final _that = this;
switch (_that) {
case _Creator() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'avatar')  ComicImage avatar, @JsonKey(name: 'onTap')  Map<String, dynamic> onTap, @JsonKey(name: 'extern')  Map<String, dynamic> extern)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Creator() when $default != null:
return $default(_that.id,_that.name,_that.avatar,_that.onTap,_that.extern);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'avatar')  ComicImage avatar, @JsonKey(name: 'onTap')  Map<String, dynamic> onTap, @JsonKey(name: 'extern')  Map<String, dynamic> extern)  $default,) {final _that = this;
switch (_that) {
case _Creator():
return $default(_that.id,_that.name,_that.avatar,_that.onTap,_that.extern);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'avatar')  ComicImage avatar, @JsonKey(name: 'onTap')  Map<String, dynamic> onTap, @JsonKey(name: 'extern')  Map<String, dynamic> extern)?  $default,) {final _that = this;
switch (_that) {
case _Creator() when $default != null:
return $default(_that.id,_that.name,_that.avatar,_that.onTap,_that.extern);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Creator implements Creator {
  const _Creator({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'name') required this.name, @JsonKey(name: 'avatar') required this.avatar, @JsonKey(name: 'onTap')  Map<String, dynamic> onTap = const {}, @JsonKey(name: 'extern')  Map<String, dynamic> extern = const {}}): _onTap = onTap,_extern = extern;
  factory _Creator.fromJson(Map<String, dynamic> json) => _$CreatorFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'name') final  String name;
@override@JsonKey(name: 'avatar') final  ComicImage avatar;
 final  Map<String, dynamic> _onTap;
@override@JsonKey(name: 'onTap') Map<String, dynamic> get onTap {
  if (_onTap is EqualUnmodifiableMapView) return _onTap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_onTap);
}

 final  Map<String, dynamic> _extern;
@override@JsonKey(name: 'extern') Map<String, dynamic> get extern {
  if (_extern is EqualUnmodifiableMapView) return _extern;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extern);
}


/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatorCopyWith<_Creator> get copyWith => __$CreatorCopyWithImpl<_Creator>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreatorToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Creator&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&const DeepCollectionEquality().equals(other.onTap, _onTap)&&const DeepCollectionEquality().equals(other.extern, _extern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,avatar,const DeepCollectionEquality().hash(_onTap),const DeepCollectionEquality().hash(_extern));
}

@override
String toString() {
    return 'Creator(id: $id, name: $name, avatar: $avatar, onTap: $onTap, extern: $extern)';
}


}

/// @nodoc
abstract mixin class _$CreatorCopyWith<$Res> implements $CreatorCopyWith<$Res> {
  factory _$CreatorCopyWith(_Creator value, $Res Function(_Creator) _then) = __$CreatorCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'name') String name,@JsonKey(name: 'avatar') ComicImage avatar,@JsonKey(name: 'onTap') Map<String, dynamic> onTap,@JsonKey(name: 'extern') Map<String, dynamic> extern
});


@override $ComicImageCopyWith<$Res> get avatar;

}
/// @nodoc
class __$CreatorCopyWithImpl<$Res>
    implements _$CreatorCopyWith<$Res> {
  __$CreatorCopyWithImpl(this._self, this._then);

  final _Creator _self;
  final $Res Function(_Creator) _then;

/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? avatar = null,Object? onTap = null,Object? extern = null,}) {
  return _then(_Creator(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as ComicImage,onTap: null == onTap ? _self._onTap : onTap // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,extern: null == extern ? _self._extern : extern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicImageCopyWith<$Res> get avatar {
  
  return $ComicImageCopyWith<$Res>(_self.avatar, (value) {
    return _then(_self.copyWith(avatar: value));
  });
}
}

// dart format on

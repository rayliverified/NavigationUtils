// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['uid'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? 'Guest',
      photoUrl: json['photoUrl'] as String? ??
          'https://www.gravatar.com/avatar/084e0343a0486ff05530df6c705c8bb9.png?s=200&d=retro&r=pg',
      initial: json['initial'] as bool? ?? false,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'uid': instance.id,
      'email': instance.email,
      'name': instance.name,
      'photoUrl': instance.photoUrl,
      'initial': instance.initial,
    };

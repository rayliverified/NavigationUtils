import 'package:json_annotation/json_annotation.dart';

part 'model_user.g.dart';

@JsonSerializable()
class UserModel {
  @JsonKey(name: 'uid')
  String id;
  String email;
  String? firstName;
  String? lastName;
  String photoUrl;

  String? get fullName => firstName != null && lastName != null
      ? '$firstName $lastName'
      : firstName ?? lastName;

  bool get empty => id.isEmpty && email.isEmpty;

  UserModel({
    required this.id,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    this.photoUrl =
        'https://www.gravatar.com/avatar/084e0343a0486ff05530df6c705c8bb9.png?s=200&d=retro&r=pg',
  });

  factory UserModel.empty() => UserModel(id: '', email: '');

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? photoUrl,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        photoUrl: photoUrl ?? this.photoUrl,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  @override
  String toString() => toJson().toString();
}

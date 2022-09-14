import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model_user.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
  @JsonKey(name: 'uid')
  final String id;
  final String email;
  final String name;
  final String photoUrl;

  const UserModel({
    required this.id,
    required this.email,
    this.name = 'Guest',
    this.photoUrl =
        'https://www.gravatar.com/avatar/084e0343a0486ff05530df6c705c8bb9.png?s=200&d=retro&r=pg',
  });

  factory UserModel.empty() => const UserModel(id: '', email: '');

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name ?? this.name,
        photoUrl: photoUrl ?? this.photoUrl,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  @override
  List<Object?> get props => [id, email, name, photoUrl];

  @override
  String toString() => toJson().toString();
}

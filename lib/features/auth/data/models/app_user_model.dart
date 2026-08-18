import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/auth/domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.displayName,
    required super.primaryIdentifier,
    required super.role,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) => AppUserModel(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        primaryIdentifier: json['primaryIdentifier'] as String,
        role: UserRole.fromValue(json['role'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'primaryIdentifier': primaryIdentifier,
        'role': role.name,
      };
}

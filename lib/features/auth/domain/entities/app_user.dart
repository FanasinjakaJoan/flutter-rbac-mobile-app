import 'package:equatable/equatable.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.primaryIdentifier,
    required this.role,
  });

  final String id;
  final String displayName;
  final String primaryIdentifier;
  final UserRole role;

  @override
  List<Object> get props => [id, displayName, primaryIdentifier, role];
}

import 'package:equatable/equatable.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';

/// Compte tel qu'affiché dans l'annuaire d'administration.
class ManagedUser extends Equatable {
  const ManagedUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    this.isActive = true,
  });

  final String id;
  final String displayName;
  final String email;
  final UserRole role;
  final bool isActive;

  /// Initiales affichées dans l'avatar de la liste.
  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Vrai si [query] correspond au nom, à l'e-mail ou à l'identifiant.
  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return displayName.toLowerCase().contains(normalized) ||
        email.toLowerCase().contains(normalized) ||
        id.toLowerCase().contains(normalized);
  }

  ManagedUser copyWith({UserRole? role, bool? isActive}) => ManagedUser(
        id: id,
        displayName: displayName,
        email: email,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
      );

  @override
  List<Object?> get props => [id, displayName, email, role, isActive];
}

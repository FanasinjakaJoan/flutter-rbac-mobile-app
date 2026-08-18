import 'package:flutter/material.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';

/// Couleurs d'accentuation partagées entre la liste des utilisateurs et la
/// matrice de permissions.
abstract final class RoleVisuals {
  static Color color(UserRole role) => switch (role) {
        UserRole.admin => const Color(0xFF3154D9),
        UserRole.student => const Color(0xFF14866D),
        UserRole.technician => const Color(0xFFD76A20),
      };

  static IconData icon(UserRole role) => switch (role) {
        UserRole.admin => Icons.admin_panel_settings_outlined,
        UserRole.student => Icons.school_outlined,
        UserRole.technician => Icons.build_outlined,
      };
}

/// Puce colorée indiquant le rôle d'un compte.
class RoleBadge extends StatelessWidget {
  const RoleBadge({required this.role, super.key, this.compact = false});

  final UserRole role;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = RoleVisuals.color(role);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(RoleVisuals.icon(role), size: compact ? 14 : 16, color: color),
          const SizedBox(width: 6),
          Text(
            compact ? role.shortLabel : role.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

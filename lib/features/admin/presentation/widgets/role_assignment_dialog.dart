import 'package:flutter/material.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/admin/domain/entities/managed_user.dart';
import 'package:rbac_mobile_app/features/admin/presentation/widgets/role_badge.dart';

/// Boîte de dialogue de réaffectation de rôle.
///
/// Retourne le rôle sélectionné, ou `null` si l'administrateur annule ou
/// confirme sans changement.
class RoleAssignmentDialog extends StatefulWidget {
  const RoleAssignmentDialog({required this.user, super.key});

  final ManagedUser user;

  static Future<UserRole?> show(BuildContext context, ManagedUser user) =>
      showDialog<UserRole>(
        context: context,
        builder: (_) => RoleAssignmentDialog(user: user),
      );

  @override
  State<RoleAssignmentDialog> createState() => _RoleAssignmentDialogState();
}

class _RoleAssignmentDialogState extends State<RoleAssignmentDialog> {
  late UserRole _selectedRole = widget.user.role;

  bool get _hasChanged => _selectedRole != widget.user.role;

  @override
  Widget build(BuildContext context) => AlertDialog(
        key: const Key('role-assignment-dialog'),
        title: const Text('Modifier le rôle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.user.displayName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              widget.user.email,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            // ListTile sélectionnable plutôt que RadioListTile : l'API
            // `groupValue` des radios est dépréciée dans les versions récentes
            // de Flutter, ce composant reste stable et testable.
            for (final role in UserRole.values)
              ListTile(
                key: Key('role-option-${role.name}'),
                onTap: () => setState(() => _selectedRole = role),
                selected: _selectedRole == role,
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(
                  RoleVisuals.icon(role),
                  color: RoleVisuals.color(role),
                ),
                title: Text(role.label),
                trailing: Icon(
                  _selectedRole == role
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _selectedRole == role
                      ? RoleVisuals.color(role)
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const Key('role-assignment-confirm'),
            onPressed: _hasChanged
                ? () => Navigator.of(context).pop(_selectedRole)
                : null,
            child: const Text('Enregistrer'),
          ),
        ],
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rbac_mobile_app/core/security/app_permission.dart';
import 'package:rbac_mobile_app/core/security/rbac_policy.dart';
import 'package:rbac_mobile_app/features/admin/presentation/widgets/role_badge.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';

/// Écran `/profile`, protégé par la permission `editProfile`.
///
/// Il récapitule également les droits effectifs de la session, ce qui rend
/// visible en direct toute modification faite dans la matrice.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state.user;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final granted = state.permissions.permissionsOf(user.role);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(
            RbacPolicy.landingFor(user.role, state.permissions),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          RoleVisuals.color(user.role).withValues(alpha: 0.15),
                      foregroundColor: RoleVisuals.color(user.role),
                      child: Text(
                        user.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(user.primaryIdentifier),
                          const SizedBox(height: 8),
                          RoleBadge(role: user.role),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Droits effectifs',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final permission in AppPermission.values)
                      ListTile(
                        key: Key('profile-permission-${permission.name}'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(
                          granted.contains(permission)
                              ? Icons.check_circle_rounded
                              : Icons.remove_circle_outline_rounded,
                          color: granted.contains(permission)
                              ? Colors.green.shade600
                              : Theme.of(context).colorScheme.outline,
                        ),
                        title: Text(permission.label),
                        subtitle: Text(permission.description),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

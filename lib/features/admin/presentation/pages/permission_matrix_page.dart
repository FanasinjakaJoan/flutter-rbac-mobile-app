import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rbac_mobile_app/core/constants/app_routes.dart';
import 'package:rbac_mobile_app/core/security/app_permission.dart';
import 'package:rbac_mobile_app/core/security/permission_matrix.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/admin/presentation/cubit/permission_matrix_cubit.dart';
import 'package:rbac_mobile_app/features/admin/presentation/widgets/role_badge.dart';

/// Écran `/admin/permissions` : matrice interactive rôles × permissions.
///
/// Chaque case bascule un droit en temps réel ; le changement est persisté puis
/// diffusé à toutes les sessions actives via le `RbacService`.
class PermissionMatrixPage extends StatelessWidget {
  const PermissionMatrixPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<PermissionMatrixCubit, PermissionMatrixState>(
        listenWhen: (previous, current) =>
            previous.feedback != current.feedback && current.feedback != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.feedback!),
                duration: const Duration(seconds: 2),
              ),
            );
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('Matrice des permissions'),
            leading: IconButton(
              tooltip: 'Retour',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go(AppRoutes.adminDashboard),
            ),
            actions: [
              TextButton.icon(
                key: const Key('permission-matrix-reset'),
                onPressed: state.isDefault
                    ? null
                    : () =>
                        context.read<PermissionMatrixCubit>().resetToDefaults(),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Réinitialiser'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MatrixHeader(state: state),
                      const SizedBox(height: 18),
                      _MatrixTable(state: state),
                      const SizedBox(height: 18),
                      const _MatrixLegend(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _MatrixHeader extends StatelessWidget {
  const _MatrixHeader({required this.state});

  final PermissionMatrixState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Contrôle d’accès basé sur les rôles',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Chip(
                key: const Key('permission-granted-count'),
                label: Text('${state.matrix.grantedCount} droits actifs'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Activez ou désactivez un droit : la modification est appliquée '
            'immédiatement aux gardes de navigation et enregistrée localement.',
          ),
        ],
      ),
    );
  }
}

class _MatrixTable extends StatelessWidget {
  const _MatrixTable({required this.state});

  final PermissionMatrixState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const permissionColumnWidth = 220.0;
            const roleColumnWidth = 132.0;
            final requiredWidth = permissionColumnWidth +
                roleColumnWidth * UserRole.values.length;
            final table = SizedBox(
              width: requiredWidth,
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: permissionColumnWidth),
                      for (final role in UserRole.values)
                        SizedBox(
                          width: roleColumnWidth,
                          child: Center(child: RoleBadge(role: role, compact: true)),
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  for (final permission in AppPermission.values) ...[
                    _MatrixRow(
                      permission: permission,
                      state: state,
                      permissionColumnWidth: permissionColumnWidth,
                      roleColumnWidth: roleColumnWidth,
                    ),
                    if (permission != AppPermission.values.last)
                      Divider(
                        height: 16,
                        color: colors.outlineVariant.withValues(alpha: 0.5),
                      ),
                  ],
                ],
              ),
            );

            if (requiredWidth <= constraints.maxWidth) {
              return table;
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: table,
            );
          },
        ),
      ),
    );
  }
}

class _MatrixRow extends StatelessWidget {
  const _MatrixRow({
    required this.permission,
    required this.state,
    required this.permissionColumnWidth,
    required this.roleColumnWidth,
  });

  final AppPermission permission;
  final PermissionMatrixState state;
  final double permissionColumnWidth;
  final double roleColumnWidth;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: permissionColumnWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    permission.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    permission.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          for (final role in UserRole.values)
            SizedBox(
              width: roleColumnWidth,
              child: Center(
                child: _MatrixCell(
                  role: role,
                  permission: permission,
                  granted: state.matrix.can(role, permission),
                  isPending: state.isPending(role, permission),
                ),
              ),
            ),
        ],
      );
}

class _MatrixCell extends StatelessWidget {
  const _MatrixCell({
    required this.role,
    required this.permission,
    required this.granted,
    required this.isPending,
  });

  final UserRole role;
  final AppPermission permission;
  final bool granted;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final locked = PermissionMatrix.isLocked(role, permission);
    if (isPending) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    return Tooltip(
      message: locked
          ? 'Permission verrouillée pour préserver l’accès administrateur'
          : granted
              ? 'Retirer « ${permission.label} » à ${role.label}'
              : 'Accorder « ${permission.label} » à ${role.label}',
      child: Switch(
        key: Key('permission-${role.name}-${permission.name}'),
        value: granted,
        onChanged: locked
            ? null
            : (_) => context.read<PermissionMatrixCubit>().toggle(
                  role: role,
                  permission: permission,
                ),
      ),
    );
  }
}

class _MatrixLegend extends StatelessWidget {
  const _MatrixLegend();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'La permission « Gérer les permissions » reste toujours active '
              'pour le rôle Administrateur afin d’éviter tout verrouillage '
              'définitif de la console.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
}

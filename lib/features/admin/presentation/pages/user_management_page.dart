import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rbac_mobile_app/core/constants/app_routes.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/admin/domain/entities/managed_user.dart';
import 'package:rbac_mobile_app/features/admin/presentation/cubit/user_directory_cubit.dart';
import 'package:rbac_mobile_app/features/admin/presentation/widgets/role_assignment_dialog.dart';
import 'package:rbac_mobile_app/features/admin/presentation/widgets/role_badge.dart';

/// Écran `/admin/users` : annuaire des comptes avec recherche, filtre par rôle
/// et réaffectation dynamique.
class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Gestion des utilisateurs'),
          leading: IconButton(
            tooltip: 'Retour',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go(AppRoutes.adminDashboard),
          ),
          actions: [
            IconButton(
              key: const Key('user-directory-refresh'),
              tooltip: 'Rafraîchir',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => context.read<UserDirectoryCubit>().loadUsers(),
            ),
            IconButton(
              tooltip: 'Matrice des permissions',
              icon: const Icon(Icons.grid_view_rounded),
              onPressed: () => context.go(AppRoutes.adminPermissions),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: BlocConsumer<UserDirectoryCubit, UserDirectoryState>(
                listenWhen: (previous, current) =>
                    previous.errorMessage != current.errorMessage ||
                    previous.lastUpdatedUserId != current.lastUpdatedUserId,
                listener: (context, state) {
                  final messenger = ScaffoldMessenger.of(context);
                  if (state.errorMessage != null) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(state.errorMessage!)),
                    );
                  } else if (state.lastUpdatedUserId != null) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Rôle mis à jour.')),
                    );
                  }
                },
                builder: (context, state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _SearchAndFilters(state: state),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: _UserList(state: state)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({required this.state});

  final UserDirectoryState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UserDirectoryCubit>();
    final counts = state.roleCounts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('user-search-field'),
          onChanged: cubit.search,
          decoration: const InputDecoration(
            hintText: 'Rechercher un nom, un e-mail ou un identifiant',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              key: const Key('role-filter-all'),
              label: Text('Tous (${state.users.length})'),
              selected: state.roleFilter == null,
              onSelected: (_) => cubit.filterByRole(null),
            ),
            for (final role in UserRole.values)
              FilterChip(
                key: Key('role-filter-${role.name}'),
                avatar: Icon(
                  RoleVisuals.icon(role),
                  size: 18,
                  color: RoleVisuals.color(role),
                ),
                label: Text('${role.label} (${counts[role] ?? 0})'),
                selected: state.roleFilter == role,
                onSelected: (selected) =>
                    cubit.filterByRole(selected ? role : null),
              ),
          ],
        ),
      ],
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList({required this.state});

  final UserDirectoryState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final users = state.filteredUsers;
    if (users.isEmpty) {
      return Center(
        key: const Key('user-list-empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              'Aucun utilisateur ne correspond à ces critères.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      key: const Key('user-list'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _UserTile(
        user: users[index],
        isUpdating: state.updatingUserId == users[index].id,
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.isUpdating});

  final ManagedUser user;
  final bool isUpdating;

  Future<void> _editRole(BuildContext context) async {
    final cubit = context.read<UserDirectoryCubit>();
    final role = await RoleAssignmentDialog.show(context, user);
    if (role != null && role != user.role) {
      await cubit.changeRole(userId: user.id, role: role);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = RoleVisuals.color(user.role);
    return Card(
      key: Key('user-card-${user.id}'),
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          child: Text(
            user.initials,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (!user.isActive) ...[
              const SizedBox(width: 8),
              const Chip(
                label: Text('Inactif'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            RoleBadge(role: user.role, compact: true),
          ],
        ),
        trailing: isUpdating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : IconButton(
                key: Key('edit-role-${user.id}'),
                tooltip: 'Modifier le rôle',
                icon: const Icon(Icons.manage_accounts_outlined),
                onPressed: () => _editRole(context),
              ),
      ),
    );
  }
}

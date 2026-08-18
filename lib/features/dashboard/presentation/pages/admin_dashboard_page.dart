import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rbac_mobile_app/core/constants/app_routes.dart';
import 'package:rbac_mobile_app/core/security/app_permission.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rbac_mobile_app/features/dashboard/presentation/pages/dashboard_scaffold.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state.user;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final matrix = state.permissions;
    return DashboardScaffold(
      title: 'Administration',
      subtitle: 'Pilotez les utilisateurs, rôles et accès de la plateforme.',
      user: user,
      accentColor: const Color(0xFF3154D9),
      metrics: [
        const DashboardMetric(
          label: 'Utilisateurs actifs',
          value: '128',
          icon: Icons.people_alt_outlined,
        ),
        const DashboardMetric(
          label: 'Rôles configurés',
          value: '3',
          icon: Icons.badge_outlined,
        ),
        DashboardMetric(
          label: 'Droits accordés',
          value: '${matrix.grantedCount}',
          icon: Icons.policy_outlined,
        ),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardSection(
            title: 'Gouvernance des accès',
            icon: Icons.admin_panel_settings_outlined,
            children: [
              if (state.can(AppPermission.manageUsers))
                _AdminAction(
                  key: const Key('admin-action-users'),
                  icon: Icons.groups_2_outlined,
                  title: 'Gestion des utilisateurs',
                  subtitle: 'Rechercher, filtrer et réaffecter les rôles',
                  route: AppRoutes.adminUsers,
                ),
              if (state.can(AppPermission.managePermissions))
                _AdminAction(
                  key: const Key('admin-action-permissions'),
                  icon: Icons.grid_view_rounded,
                  title: 'Matrice des permissions',
                  subtitle: 'Basculer les droits rôle par rôle en temps réel',
                  route: AppRoutes.adminPermissions,
                ),
              if (state.can(AppPermission.viewReports))
                _AdminAction(
                  key: const Key('admin-action-reports'),
                  icon: Icons.insights_outlined,
                  title: 'Rapports d’activité',
                  subtitle: 'Consulter les journaux et statistiques d’accès',
                  route: AppRoutes.reports,
                ),
            ],
          ),
          const SizedBox(height: 20),
          const DashboardSection(
            title: 'Activité récente',
            icon: Icons.history_rounded,
            children: [
              DashboardListItem(
                icon: Icons.person_add_alt_1,
                title: 'Nouvel utilisateur étudiant',
                subtitle: 'Créé il y a 12 minutes',
                trailing: Chip(label: Text('Étudiant')),
              ),
              DashboardListItem(
                icon: Icons.manage_accounts_outlined,
                title: 'Permissions mises à jour',
                subtitle: 'Rôle technicien · il y a 1 heure',
                trailing: Chip(label: Text('RBAC')),
              ),
              DashboardListItem(
                icon: Icons.security_outlined,
                title: 'Connexion administrative',
                subtitle: 'Session sécurisée · aujourd’hui à 09:41',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  const _AdminAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => context.go(route),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      );
}

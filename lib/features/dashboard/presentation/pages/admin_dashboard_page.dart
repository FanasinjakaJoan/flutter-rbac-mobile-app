import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rbac_mobile_app/features/dashboard/presentation/pages/dashboard_scaffold.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) {
      return const SizedBox.shrink();
    }
    return DashboardScaffold(
      title: 'Administration',
      subtitle: 'Pilotez les utilisateurs, rôles et accès de la plateforme.',
      user: user,
      accentColor: const Color(0xFF3154D9),
      metrics: const [
        DashboardMetric(
          label: 'Utilisateurs actifs',
          value: '128',
          icon: Icons.people_alt_outlined,
        ),
        DashboardMetric(
          label: 'Rôles configurés',
          value: '3',
          icon: Icons.badge_outlined,
        ),
        DashboardMetric(
          label: 'Événements d’audit',
          value: '24',
          icon: Icons.policy_outlined,
        ),
      ],
      content: const DashboardSection(
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
    );
  }
}

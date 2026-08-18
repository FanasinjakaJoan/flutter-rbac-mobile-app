import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rbac_mobile_app/features/dashboard/presentation/pages/dashboard_scaffold.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) {
      return const SizedBox.shrink();
    }
    return DashboardScaffold(
      title: 'Espace étudiant',
      subtitle: 'Retrouvez votre parcours et vos prochaines échéances.',
      user: user,
      accentColor: const Color(0xFF14866D),
      metrics: const [
        DashboardMetric(
          label: 'Cours suivis',
          value: '6',
          icon: Icons.menu_book_outlined,
        ),
        DashboardMetric(
          label: 'Travaux à rendre',
          value: '2',
          icon: Icons.assignment_outlined,
        ),
        DashboardMetric(
          label: 'Progression moyenne',
          value: '78 %',
          icon: Icons.trending_up_rounded,
        ),
      ],
      content: const DashboardSection(
        title: 'Prochaines échéances',
        icon: Icons.event_outlined,
        children: [
          DashboardListItem(
            icon: Icons.code_rounded,
            title: 'Projet Architecture mobile',
            subtitle: 'À remettre vendredi à 18:00',
            trailing: Chip(label: Text('Prioritaire')),
          ),
          DashboardListItem(
            icon: Icons.calculate_outlined,
            title: 'Quiz de mathématiques',
            subtitle: 'Disponible demain à 08:00',
          ),
          DashboardListItem(
            icon: Icons.groups_outlined,
            title: 'Atelier en équipe',
            subtitle: 'Salle B12 · lundi à 10:30',
          ),
        ],
      ),
    );
  }
}

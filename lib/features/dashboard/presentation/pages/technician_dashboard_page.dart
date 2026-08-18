import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rbac_mobile_app/features/dashboard/presentation/pages/dashboard_scaffold.dart';

class TechnicianDashboardPage extends StatelessWidget {
  const TechnicianDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) {
      return const SizedBox.shrink();
    }
    return DashboardScaffold(
      title: 'Console technique',
      subtitle: 'Suivez les interventions et la santé des équipements.',
      user: user,
      accentColor: const Color(0xFFD76A20),
      metrics: const [
        DashboardMetric(
          label: 'Tickets ouverts',
          value: '9',
          icon: Icons.confirmation_number_outlined,
        ),
        DashboardMetric(
          label: 'Interventions du jour',
          value: '4',
          icon: Icons.build_outlined,
        ),
        DashboardMetric(
          label: 'Équipements en ligne',
          value: '96 %',
          icon: Icons.router_outlined,
        ),
      ],
      content: const DashboardSection(
        title: 'File d’intervention',
        icon: Icons.handyman_outlined,
        children: [
          DashboardListItem(
            icon: Icons.wifi_off_outlined,
            title: 'Réseau indisponible · Bâtiment C',
            subtitle: 'Ticket #2048 · ouvert il y a 18 min',
            trailing: Chip(label: Text('Urgent')),
          ),
          DashboardListItem(
            icon: Icons.print_disabled_outlined,
            title: 'Imprimante du secrétariat',
            subtitle: 'Ticket #2047 · diagnostic en cours',
          ),
          DashboardListItem(
            icon: Icons.computer_outlined,
            title: 'Mise à jour salle informatique',
            subtitle: 'Planifiée aujourd’hui à 16:00',
          ),
        ],
      ),
    );
  }
}

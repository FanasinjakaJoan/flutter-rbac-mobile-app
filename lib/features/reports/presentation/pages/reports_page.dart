import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rbac_mobile_app/core/security/rbac_policy.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';

/// Écran `/reports`, protégé par la permission `viewReports`.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports'),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(
            user == null
                ? '/'
                : RbacPolicy.landingFor(user.role, state.permissions),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            _ReportCard(
              icon: Icons.insights_rounded,
              title: 'Activité hebdomadaire',
              subtitle: '1 248 connexions · +12 % sur 7 jours',
            ),
            SizedBox(height: 12),
            _ReportCard(
              icon: Icons.shield_moon_outlined,
              title: 'Audit des accès refusés',
              subtitle: '18 redirections vers l’écran non autorisé',
            ),
            SizedBox(height: 12),
            _ReportCard(
              icon: Icons.timeline_rounded,
              title: 'Évolution des rôles',
              subtitle: '4 réaffectations enregistrées ce mois-ci',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(subtitle),
        ),
      );
}

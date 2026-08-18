import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rbac_mobile_app/core/security/rbac_policy.dart';
import 'package:rbac_mobile_app/features/auth/domain/entities/app_user.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';

class DashboardMetric {
  const DashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class DashboardScaffold extends StatelessWidget {
  const DashboardScaffold({
    required this.title,
    required this.subtitle,
    required this.user,
    required this.accentColor,
    required this.metrics,
    required this.content,
    super.key,
  });

  final String title;
  final String subtitle;
  final AppUser user;
  final Color accentColor;
  final List<DashboardMetric> metrics;
  final Widget content;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              tooltip: 'Se déconnecter',
              onPressed: () => context
                  .read<AuthBloc>()
                  .add(const LogoutRequested()),
              icon: const Icon(Icons.logout_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: _AppDrawer(user: user, accentColor: accentColor),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WelcomeBanner(
                      user: user,
                      subtitle: subtitle,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Vue d’ensemble',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 850
                            ? 3
                            : constraints.maxWidth >= 540
                                ? 2
                                : 1;
                        final spacing = 12.0;
                        final width = (constraints.maxWidth -
                                (spacing * (columns - 1))) /
                            columns;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final metric in metrics)
                              SizedBox(
                                width: width,
                                child: _MetricCard(
                                  metric: metric,
                                  accentColor: accentColor,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    content,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.user,
    required this.subtitle,
    required this.accentColor,
  });

  final AppUser user;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor, accentColor.withValues(alpha: 0.72)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              child: Text(
                user.displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, ${user.displayName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, required this.accentColor});

  final DashboardMetric metric;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(metric.icon, color: accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      metric.label,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.user, required this.accentColor});

  final AppUser user;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => NavigationDrawer(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          Navigator.of(context).pop();
          if (index == 0) {
            context.go(RbacPolicy.dashboardFor(user.role));
          } else {
            context.read<AuthBloc>().add(const LogoutRequested());
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  child: Text(user.displayName.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.role.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: Text('Tableau de bord'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.logout_rounded),
            label: Text('Se déconnecter'),
          ),
        ],
      );
}

class DashboardSection extends StatelessWidget {
  const DashboardSection({
    required this.title,
    required this.icon,
    required this.children,
    super.key,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const Divider(height: 28),
              ...children,
            ],
          ),
        ),
      );
}

class DashboardListItem extends StatelessWidget {
  const DashboardListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
      );
}

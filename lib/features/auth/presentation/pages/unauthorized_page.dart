import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rbac_mobile_app/core/security/rbac_policy.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';

class UnauthorizedPage extends StatelessWidget {
  const UnauthorizedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.gpp_bad_outlined,
                        size: 72,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Accès non autorisé',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Votre rôle ne dispose pas de la permission nécessaire '
                        'pour consulter cette page.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: user == null
                            ? null
                            : () => context.go(
                                  RbacPolicy.dashboardFor(user.role),
                                ),
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Retour à mon tableau de bord'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context
                            .read<AuthBloc>()
                            .add(const LogoutRequested()),
                        child: const Text('Se déconnecter'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

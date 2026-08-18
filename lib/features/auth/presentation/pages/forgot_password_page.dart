import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rbac_mobile_app/core/constants/app_routes.dart';
import 'package:rbac_mobile_app/core/widgets/auth_page_shell.dart';
import 'package:rbac_mobile_app/features/auth/presentation/cubit/password_recovery_cubit.dart';
import 'package:rbac_mobile_app/features/auth/presentation/widgets/auth_validators.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context
          .read<PasswordRecoveryCubit>()
          .requestCode(_identifierController.text);
    }
  }

  @override
  Widget build(BuildContext context) => AuthPageShell(
        child: BlocConsumer<PasswordRecoveryCubit, PasswordRecoveryState>(
          listener: (context, state) {
            if (state.status == PasswordRecoveryStatus.codeSent) {
              final identifier = Uri.encodeComponent(
                _identifierController.text.trim(),
              );
              context.go('${AppRoutes.resetCode}?identifier=$identifier');
            }
          },
          builder: (context, state) {
            final isLoading =
                state.status == PasswordRecoveryStatus.loading;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton.filledTonal(
                          tooltip: 'Retour à la connexion',
                          onPressed: () => context.go(AppRoutes.login),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Mot de passe oublié',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Indiquez l’email ou le matricule associé à votre compte. '
                        'Un code de réinitialisation vous sera envoyé.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const Key('recoveryIdentifierField'),
                        controller: _identifierController,
                        enabled: !isLoading,
                        validator: AuthValidators.recoveryIdentifier,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Email ou matricule',
                          hintText: 'student@example.com',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: isLoading ? null : _submit,
                        icon: isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.mark_email_read_outlined),
                        label: Text(
                          isLoading ? 'Envoi…' : 'Envoyer le code',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
}

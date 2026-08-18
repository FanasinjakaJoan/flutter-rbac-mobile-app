import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rbac_mobile_app/core/constants/app_routes.dart';
import 'package:rbac_mobile_app/core/widgets/auth_page_shell.dart';
import 'package:rbac_mobile_app/features/auth/presentation/cubit/password_recovery_cubit.dart';
import 'package:rbac_mobile_app/features/auth/presentation/widgets/auth_validators.dart';

class ResetCodePage extends StatefulWidget {
  const ResetCodePage({required this.identifier, super.key});

  final String identifier;

  @override
  State<ResetCodePage> createState() => _ResetCodePageState();
}

class _ResetCodePageState extends State<ResetCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<PasswordRecoveryCubit>().verifyCode(
            identifier: widget.identifier,
            code: _codeController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) => AuthPageShell(
        child: BlocConsumer<PasswordRecoveryCubit, PasswordRecoveryState>(
          listener: (context, state) {
            if (state.status == PasswordRecoveryStatus.verified) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Code validé. La définition du nouveau mot de passe est simulée.',
                  ),
                ),
              );
              context.go(AppRoutes.login);
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
                          tooltip: 'Retour',
                          onPressed: () => context.go(AppRoutes.forgotPassword),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Saisissez le code',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Code envoyé pour ${widget.identifier}. '
                        'Dans cette démo, utilisez 123456.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const Key('resetCodeField'),
                        controller: _codeController,
                        enabled: !isLoading,
                        validator: AuthValidators.resetCode,
                        autofocus: true,
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Code à 6 chiffres',
                          prefixIcon: Icon(Icons.password_rounded),
                          counterText: '',
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
                            : const Icon(Icons.verified_user_outlined),
                        label: Text(isLoading ? 'Vérification…' : 'Vérifier'),
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

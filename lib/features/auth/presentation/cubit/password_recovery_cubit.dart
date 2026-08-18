import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rbac_mobile_app/core/error/auth_exception.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/request_password_reset.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/verify_reset_code.dart';
import 'package:rbac_mobile_app/features/auth/presentation/cubit/password_recovery_state.dart';

export 'password_recovery_state.dart';

class PasswordRecoveryCubit extends Cubit<PasswordRecoveryState> {
  PasswordRecoveryCubit({
    required RequestPasswordReset requestPasswordReset,
    required VerifyResetCode verifyResetCode,
  })  : _requestPasswordReset = requestPasswordReset,
        _verifyResetCode = verifyResetCode,
        super(const PasswordRecoveryState());

  final RequestPasswordReset _requestPasswordReset;
  final VerifyResetCode _verifyResetCode;

  Future<void> requestCode(String identifier) async {
    emit(const PasswordRecoveryState(
      status: PasswordRecoveryStatus.loading,
    ));
    try {
      await _requestPasswordReset(identifier);
      emit(const PasswordRecoveryState(
        status: PasswordRecoveryStatus.codeSent,
      ));
    } on AuthException catch (error) {
      emit(PasswordRecoveryState(
        status: PasswordRecoveryStatus.failure,
        errorMessage: error.message,
      ));
    } on Object {
      emit(const PasswordRecoveryState(
        status: PasswordRecoveryStatus.failure,
        errorMessage: 'Impossible d’envoyer le code pour le moment.',
      ));
    }
  }

  Future<void> verifyCode({
    required String identifier,
    required String code,
  }) async {
    emit(const PasswordRecoveryState(
      status: PasswordRecoveryStatus.loading,
    ));
    try {
      final isValid = await _verifyResetCode(
        identifier: identifier,
        code: code,
      );
      if (isValid) {
        emit(const PasswordRecoveryState(
          status: PasswordRecoveryStatus.verified,
        ));
      } else {
        emit(const PasswordRecoveryState(
          status: PasswordRecoveryStatus.failure,
          errorMessage: 'Le code saisi est incorrect.',
        ));
      }
    } on AuthException catch (error) {
      emit(PasswordRecoveryState(
        status: PasswordRecoveryStatus.failure,
        errorMessage: error.message,
      ));
    } on Object {
      emit(const PasswordRecoveryState(
        status: PasswordRecoveryStatus.failure,
        errorMessage: 'Impossible de vérifier le code.',
      ));
    }
  }
}

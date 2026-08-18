import 'package:equatable/equatable.dart';

enum PasswordRecoveryStatus { initial, loading, codeSent, verified, failure }

class PasswordRecoveryState extends Equatable {
  const PasswordRecoveryState({
    this.status = PasswordRecoveryStatus.initial,
    this.errorMessage,
  });

  final PasswordRecoveryStatus status;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, errorMessage];
}

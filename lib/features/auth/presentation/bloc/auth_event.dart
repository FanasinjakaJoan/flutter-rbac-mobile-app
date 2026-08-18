import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

final class AppStarted extends AuthEvent {
  const AppStarted();
}

final class LoginRequested extends AuthEvent {
  const LoginRequested({required this.identifier, required this.password});

  final String identifier;
  final String password;

  @override
  List<Object> get props => [identifier, password];
}

final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

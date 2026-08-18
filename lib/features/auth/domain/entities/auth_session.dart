import 'package:equatable/equatable.dart';
import 'package:rbac_mobile_app/features/auth/domain/entities/app_user.dart';

class AuthSession extends Equatable {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final AppUser user;

  @override
  List<Object> get props => [accessToken, user];
}

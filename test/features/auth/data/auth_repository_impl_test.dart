import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_mobile_app/core/error/auth_exception.dart';
import 'package:rbac_mobile_app/core/security/token_storage.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/auth/data/datasources/mock_auth_remote_data_source.dart';
import 'package:rbac_mobile_app/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  late InMemoryTokenStorage storage;
  late AuthRepositoryImpl repository;

  setUp(() {
    storage = InMemoryTokenStorage();
    repository = AuthRepositoryImpl(
      remoteDataSource: MockAuthRemoteDataSource(latency: Duration.zero),
      tokenStorage: storage,
    );
  });

  group('AuthRepositoryImpl.login', () {
    final cases = <(String, UserRole)>[
      ('admin@example.com', UserRole.admin),
      ('MAT-12345', UserRole.student),
      ('technician', UserRole.technician),
    ];

    for (final testCase in cases) {
      test('authentifie ${testCase.$1} avec le rôle attendu', () async {
        final session = await repository.login(
          identifier: testCase.$1,
          password: 'Password123!',
        );

        expect(session.user.role, testCase.$2);
        expect(session.accessToken.split('.'), hasLength(3));
        expect(await storage.readToken(), session.accessToken);
      });
    }

    test('refuse des informations invalides', () async {
      await expectLater(
        repository.login(
          identifier: 'admin',
          password: 'Mauvais123!',
        ),
        throwsA(isA<AuthException>()),
      );
      expect(await storage.readToken(), isNull);
    });
  });

  test('restaure une session depuis le JWT stocké', () async {
    final loggedIn = await repository.login(
      identifier: 'student@example.com',
      password: 'Password123!',
    );

    final restored = await repository.restoreSession();

    expect(restored, loggedIn);
  });

  test('supprime un jeton invalide pendant la restauration', () async {
    await storage.writeToken('jeton-invalide');

    expect(await repository.restoreSession(), isNull);
    expect(await storage.readToken(), isNull);
  });

  test('valide le code de récupération simulé', () async {
    await repository.requestPasswordReset('MAT-12345');

    expect(
      await repository.verifyResetCode(
        identifier: 'MAT-12345',
        code: '123456',
      ),
      isTrue,
    );
  });
}

class InMemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<void> deleteToken() async => token = null;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String token) async => this.token = token;
}

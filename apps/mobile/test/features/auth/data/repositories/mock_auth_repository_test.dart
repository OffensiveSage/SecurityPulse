import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:security_pulse/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:security_pulse/features/auth/data/services/secure_token_storage.dart';
import 'package:security_pulse/features/auth/domain/models/user.dart';

class _MockSecureTokenStorage extends Mock implements SecureTokenStorage {}

void main() {
  late _MockSecureTokenStorage mockStorage;
  late MockAuthRepository repository;

  setUp(() {
    mockStorage = _MockSecureTokenStorage();
    repository = MockAuthRepository(tokenStorage: mockStorage);

    // Set up default stubs for storage write operations.
    when(
      () => mockStorage.writeAccessToken(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.writeRefreshToken(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.writeExpiresAt(any()),
    ).thenAnswer((_) async {});
    when(mockStorage.clearAll).thenAnswer((_) async {});
  });

  group('MockAuthRepository', () {
    test('signIn returns tokens', () async {
      final tokens = await repository.signIn();

      expect(tokens.accessToken, equals('mock-employee'));
      expect(tokens.refreshToken, isNotNull);
      expect(tokens.isExpired, isFalse);
    });

    test('signIn stores tokens in secure storage', () async {
      await repository.signIn();

      verify(
        () => mockStorage.writeAccessToken('mock-employee'),
      ).called(1);
      verify(
        () => mockStorage.writeRefreshToken(any()),
      ).called(1);
      verify(
        () => mockStorage.writeExpiresAt(any()),
      ).called(1);
    });

    test('getCurrentUser returns mock employee', () async {
      final user = await repository.getCurrentUser('mock-employee');

      expect(user.id, equals('mock-user-001'));
      expect(user.displayName, equals('Test Employee'));
      expect(user.email, equals('employee@example.corp'));
      expect(user.role, equals(UserRole.employee));
    });

    test('signOut clears secure storage', () async {
      await repository.signOut();

      verify(mockStorage.clearAll).called(1);
    });

    test('clearTokens clears secure storage', () async {
      await repository.clearTokens();

      verify(mockStorage.clearAll).called(1);
    });

    test('getStoredTokens returns null when no token stored', () async {
      when(mockStorage.readAccessToken).thenAnswer((_) async => null);

      final tokens = await repository.getStoredTokens();

      expect(tokens, isNull);
    });

    test('getStoredTokens returns tokens when stored', () async {
      when(mockStorage.readAccessToken).thenAnswer((_) async => 'stored-token');
      when(mockStorage.readRefreshToken)
          .thenAnswer((_) async => 'stored-refresh');
      when(mockStorage.readExpiresAt).thenAnswer(
        (_) async => DateTime.now().add(const Duration(hours: 1)),
      );

      final tokens = await repository.getStoredTokens();

      expect(tokens, isNotNull);
      expect(
        tokens!.accessToken, // safe: checked above
        equals('stored-token'),
      );
      expect(tokens.refreshToken, equals('stored-refresh'));
      expect(tokens.isExpired, isFalse);
    });

    test('refreshTokens returns new tokens', () async {
      final tokens = await repository.refreshTokens('old-refresh-token');

      expect(tokens.accessToken, equals('mock-employee'));
      expect(tokens.isExpired, isFalse);
    });
  });
}

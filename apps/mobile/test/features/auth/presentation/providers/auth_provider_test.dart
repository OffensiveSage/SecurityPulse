import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:security_pulse/features/auth/domain/models/auth_tokens.dart';
import 'package:security_pulse/features/auth/domain/models/user.dart';
import 'package:security_pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:security_pulse/features/auth/presentation/providers/auth_provider.dart';
import 'package:security_pulse/features/auth/presentation/providers/auth_state.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _testUser = User(
  id: 'test-user-001',
  displayName: 'Test Employee',
  email: 'employee@example.corp',
  role: UserRole.employee,
);

final _testTokens = AuthTokens(
  accessToken: 'mock-access-token',
  refreshToken: 'mock-refresh-token',
  expiresAt: DateTime.now().add(const Duration(hours: 1)),
);

final _expiredTokens = AuthTokens(
  accessToken: 'expired-token',
  expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
);

void main() {
  late _MockAuthRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = _MockAuthRepository();
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer() {
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    return container;
  }

  group('AuthNotifier', () {
    test('initial state is AuthInitial', () {
      when(mockRepo.getStoredTokens).thenAnswer((_) async => null);

      final c = createContainer();
      expect(c.read(authProvider), isA<AuthInitial>());
    });

    test(
      'transitions to AuthAuthenticated with valid stored tokens',
      () async {
        when(mockRepo.getStoredTokens).thenAnswer((_) async => _testTokens);
        when(
          () => mockRepo.getCurrentUser(any()),
        ).thenAnswer((_) async => _testUser);

        final c = createContainer();
        c.read(authProvider);
        await Future<void>.delayed(Duration.zero);

        final state = c.read(authProvider);
        expect(state, isA<AuthAuthenticated>());
        final authenticated = state as AuthAuthenticated;
        expect(authenticated.user.id, equals('test-user-001'));
        expect(authenticated.user.displayName, equals('Test Employee'));
      },
    );

    test(
      'transitions to AuthUnauthenticated with no stored tokens',
      () async {
        when(mockRepo.getStoredTokens).thenAnswer((_) async => null);

        final c = createContainer();
        c.read(authProvider);
        await Future<void>.delayed(Duration.zero);

        expect(c.read(authProvider), isA<AuthUnauthenticated>());
      },
    );

    test(
      'transitions to AuthUnauthenticated with expired tokens',
      () async {
        when(mockRepo.getStoredTokens).thenAnswer((_) async => _expiredTokens);

        final c = createContainer();
        c.read(authProvider);
        await Future<void>.delayed(Duration.zero);

        expect(c.read(authProvider), isA<AuthUnauthenticated>());
      },
    );

    test(
      'transitions to AuthUnauthenticated on session check error',
      () async {
        when(mockRepo.getStoredTokens).thenAnswer((_) async {
          throw Exception('storage error');
        });

        final c = createContainer();
        c.read(authProvider);
        await Future<void>.delayed(Duration.zero);

        expect(c.read(authProvider), isA<AuthUnauthenticated>());
      },
    );

    group('signIn', () {
      test('transitions to AuthAuthenticated on success', () async {
        when(mockRepo.getStoredTokens).thenAnswer((_) async => null);
        when(mockRepo.signIn).thenAnswer((_) async => _testTokens);
        when(
          () => mockRepo.getCurrentUser(any()),
        ).thenAnswer((_) async => _testUser);

        final c = createContainer();
        c.read(authProvider);
        await Future<void>.delayed(Duration.zero);

        await c.read(authProvider.notifier).signIn();

        final state = c.read(authProvider);
        expect(state, isA<AuthAuthenticated>());
        expect(
          (state as AuthAuthenticated).user.email,
          equals('employee@example.corp'),
        );
      });

      test('transitions to AuthError on sign-in failure', () async {
        when(mockRepo.getStoredTokens).thenAnswer((_) async => null);
        when(mockRepo.signIn).thenAnswer((_) async {
          throw Exception('sign-in failed');
        });

        final c = createContainer();
        c.read(authProvider);
        await Future<void>.delayed(Duration.zero);

        await c.read(authProvider.notifier).signIn();

        expect(c.read(authProvider), isA<AuthError>());
      });

      test('sets loading state before completing', () async {
        when(mockRepo.getStoredTokens).thenAnswer((_) async => null);
        when(mockRepo.signIn).thenAnswer((_) async => _testTokens);
        when(
          () => mockRepo.getCurrentUser(any()),
        ).thenAnswer((_) async => _testUser);

        final c = createContainer();
        c.read(authProvider);
        await Future<void>.delayed(Duration.zero);

        final states = <AuthState>[];
        container.listen(
          authProvider,
          (prev, next) => states.add(next),
        );

        await c.read(authProvider.notifier).signIn();

        expect(states.first, isA<AuthLoading>());
      });
    });

    group('signOut', () {
      test('transitions to AuthUnauthenticated', () async {
        when(mockRepo.getStoredTokens).thenAnswer((_) async => _testTokens);
        when(
          () => mockRepo.getCurrentUser(any()),
        ).thenAnswer((_) async => _testUser);
        when(mockRepo.signOut).thenAnswer((_) async {});

        final c = createContainer();
        c.read(authProvider);
        await Future<void>.delayed(Duration.zero);
        expect(c.read(authProvider), isA<AuthAuthenticated>());

        await c.read(authProvider.notifier).signOut();

        expect(c.read(authProvider), isA<AuthUnauthenticated>());
      });

      test('calls repository signOut', () async {
        when(mockRepo.getStoredTokens).thenAnswer((_) async => _testTokens);
        when(
          () => mockRepo.getCurrentUser(any()),
        ).thenAnswer((_) async => _testUser);
        when(mockRepo.signOut).thenAnswer((_) async {});

        final c = createContainer();
        c.read(authProvider);
        await Future<void>.delayed(Duration.zero);

        await c.read(authProvider.notifier).signOut();

        verify(mockRepo.signOut).called(1);
      });

      test(
        'transitions to AuthUnauthenticated even on signOut error',
        () async {
          when(mockRepo.getStoredTokens).thenAnswer((_) async => _testTokens);
          when(
            () => mockRepo.getCurrentUser(any()),
          ).thenAnswer((_) async => _testUser);
          when(mockRepo.signOut).thenAnswer((_) async {
            throw Exception('sign-out failed');
          });

          final c = createContainer();
          c.read(authProvider);
          await Future<void>.delayed(Duration.zero);

          await c.read(authProvider.notifier).signOut();

          expect(c.read(authProvider), isA<AuthUnauthenticated>());
        },
      );
    });

    group('dismissError', () {
      test('transitions from AuthError to AuthUnauthenticated', () async {
        when(mockRepo.getStoredTokens).thenAnswer((_) async => null);
        when(mockRepo.signIn).thenAnswer((_) async {
          throw Exception('sign-in failed');
        });

        final c = createContainer();
        c.read(authProvider);
        await Future<void>.delayed(Duration.zero);

        await c.read(authProvider.notifier).signIn();
        expect(c.read(authProvider), isA<AuthError>());

        c.read(authProvider.notifier).dismissError();
        expect(c.read(authProvider), isA<AuthUnauthenticated>());
      });
    });
  });
}

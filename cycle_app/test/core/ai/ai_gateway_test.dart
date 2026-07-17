import 'package:cycle_aura/core/ai/ai_gateway.dart';
import 'package:cycle_aura/core/ai/ai_gateway_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth implements FirebaseAuth {
  /// Signed-out fake — currentUser is always null.
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  @override
  String get uid => 'test-user';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSignedInAuth implements FirebaseAuth {
  @override
  User get currentUser => _FakeUser();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AiGateway.request', () {
    test('throws auth_required when user is not signed in', () async {
      final gateway = AiGateway(auth: _FakeAuth());

      expect(
        () => gateway.request(
          message: 'hi',
          context: const {'locale': 'ar'},
        ),
        throwsA(
          isA<AiGatewayException>()
              .having((e) => e.code, 'code', 'auth_required'),
        ),
      );
    });

    test('fails closed when an adult age selection is missing', () async {
      final gateway = AiGateway(auth: _FakeSignedInAuth());

      expect(
        () => gateway.request(
          message: 'hi',
          context: const {'locale': 'ar'},
        ),
        throwsA(
          isA<AiGatewayException>()
              .having((e) => e.code, 'code', 'adult_required'),
        ),
      );
    });

    test('requires explicit consent after adult age selection', () async {
      SharedPreferences.setMockInitialValues({
        'user_age_group': 'adult',
      });
      final gateway = AiGateway(auth: _FakeSignedInAuth());

      expect(
        () => gateway.request(
          message: 'hi',
          context: const {'locale': 'ar'},
        ),
        throwsA(
          isA<AiGatewayException>()
              .having((e) => e.code, 'code', 'consent_required'),
        ),
      );
    });
  });
}

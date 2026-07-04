import 'package:cycle_aura/core/ai/ai_gateway.dart';
import 'package:cycle_aura/core/ai/ai_gateway_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuth implements FirebaseAuth {
  /// Signed-out fake — currentUser is always null.
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
  });
}

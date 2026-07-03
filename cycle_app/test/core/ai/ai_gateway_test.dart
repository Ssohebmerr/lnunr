import 'package:cycle_aura/core/ai/ai_gateway.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuth implements FirebaseAuth {
  _FakeAuth({this.user});

  final User? user;

  @override
  User? get currentUser => user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiGateway.request', () {
    test('returns null when user is not signed in', () async {
      final gateway = AiGateway(auth: _FakeAuth());

      final reply = await gateway.request(
        message: 'hi',
        context: const {'locale': 'ar'},
      );

      expect(reply, isNull);
    });
  });
}

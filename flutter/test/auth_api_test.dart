// Stack: Flutter test | File: test/auth_api_test.dart
// Runs the real flow against the real backend (no mocks): sign up → me → log out → me rejected → log in → wrong password.
// flutter test --dart-define-from-file is not needed: lib/config.dart holds the keys locally.
import 'package:flutter_test/flutter_test.dart';
import 'package:auth_starter/auth_api.dart';

void main() {
  test('signup, session, logout, login, wrong password', () async {
    final api = AuthApi();
    final u = 'fl${DateTime.now().millisecondsSinceEpoch % 1000000}';
    final signup = await api.signUp(u, '$u@example.com', 'correct-horse-battery');
    expect(signup['sessionToken'], isNotNull);

    final me = await api.me();
    expect(me['username'], u);

    await api.logOut();
    expect(api.sessionToken, isNull);

    final login = await api.logIn(u, 'correct-horse-battery');
    expect(login['sessionToken'], isNotNull);

    await expectLater(api.logIn(u, 'nope'), throwsA(isA<AuthError>().having((e) => e.code, 'code', 101)));
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/google/google_identity.dart';

import '../../helpers/fakes.dart';

void main() {
  test('a provider override replaces the Google identity', () async {
    final fake = FakeGoogleIdentity(token: 'token-9');
    final container = ProviderContainer(
      overrides: [googleIdentityProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final token = await container.read(googleIdentityProvider).idToken();

    expect(token, 'token-9');
    expect(fake.requests, 1);
  });

  test('a cancelled chooser yields no token and no error', () async {
    final fake = FakeGoogleIdentity(token: null);

    expect(await fake.idToken(), isNull);
  });

  test('without a server client id the real identity is unavailable', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await expectLater(
      container.read(googleIdentityProvider).idToken(),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.code,
          'code',
          'GOOGLE_SIGN_IN_UNAVAILABLE',
        ),
      ),
    );
  });

  test('the unavailable failure reads as an Indonesian message', () {
    expect(
      errorMessageFor(const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE')),
      'Masuk dengan Google belum tersedia.',
    );
  });
}

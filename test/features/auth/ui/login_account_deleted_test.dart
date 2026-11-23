import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/widgets/form_widgets.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'auth_ui_helpers.dart';

const _notice = 'Akun Anda sudah dihapus.';

Finder _noticeMessage() => find.widgetWithText(FormMessage, _notice);

SessionController _controller(WidgetTester tester) =>
    containerOf(tester).read(sessionControllerProvider.notifier);

/// Shows the app signed in, then ends the session as the delete account
/// screen does.
Future<void> _pumpAfterDeletion(
  WidgetTester tester, {
  bool largeText = false,
}) async {
  final app = buildTestApp(store: InMemorySessionStore(storedSession()));
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  await tester.pumpAndSettle();
  await _controller(tester).endAfterAccountDeletion();
  await tester.pumpAndSettle();
}

void main() {
  group('after the account was deleted', () {
    testWidgets('the sign in screen confirms it with a message that is not an '
        'error', (tester) async {
      await _pumpAfterDeletion(tester);

      expect(currentPath(tester), '/masuk');
      expect(find.text('Masuk ke Niscala'), findsOneWidget);
      expect(_noticeMessage(), findsOneWidget);
      expect(tester.widget<FormMessage>(_noticeMessage()).isError, isFalse);
    });

    testWidgets('the message is announced as a live region', (tester) async {
      await _pumpAfterDeletion(tester);

      expectLiveRegion(tester, _notice);
    });

    testWidgets('the message sits at the top of the form', (tester) async {
      await _pumpAfterDeletion(tester);

      final top = tester.getTopLeft(_noticeMessage()).dy;
      expect(
        top,
        lessThan(tester.getTopLeft(find.text('Masuk dengan Google')).dy),
      );
      expect(top, lessThan(tester.getTopLeft(field('Email (wajib)')).dy));
      expect(top, lessThan(tester.getTopLeft(field('Kata sandi (wajib)')).dy));
    });

    testWidgets('the form can still be used to sign in', (tester) async {
      await _pumpAfterDeletion(tester);

      expect(field('Email (wajib)'), findsOneWidget);
      expect(field('Kata sandi (wajib)'), findsOneWidget);
      expect(buttonLabelled('Masuk'), findsOneWidget);
    });

    testWidgets('a later sign in and sign out does not show the message', (
      tester,
    ) async {
      await _pumpAfterDeletion(tester);
      await type(tester, 'Email (wajib)', 'budi@example.com');
      await type(tester, 'Kata sandi (wajib)', 'rahasia panjang');
      await tapAndPump(tester, buttonLabelled('Masuk'));
      await tester.pumpAndSettle();
      expect(find.text('Masuk ke Niscala'), findsNothing);

      await _controller(tester).signOut();
      await tester.pumpAndSettle();

      expect(find.text('Masuk ke Niscala'), findsOneWidget);
      expect(find.text(_notice), findsNothing);
    });

    testWidgets('meets the accessibility guidelines', (tester) async {
      await _pumpAfterDeletion(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size', (tester) async {
      await _pumpAfterDeletion(tester, largeText: true);

      expect(tester.takeException(), isNull);
      expect(find.text(_notice), findsOneWidget);
    });
  });

  group('without a deleted account', () {
    testWidgets('a fresh start does not show the message', (tester) async {
      await pumpLogin(tester, FakeAuthRepository());

      expect(find.text('Masuk ke Niscala'), findsOneWidget);
      expect(find.text(_notice), findsNothing);
    });

    testWidgets('a normal sign out does not show the message', (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(
        buildTestApp(store: InMemorySessionStore(storedSession())),
      );
      await tester.pumpAndSettle();

      await _controller(tester).signOut();
      await tester.pumpAndSettle();

      expect(find.text('Masuk ke Niscala'), findsOneWidget);
      expect(find.text(_notice), findsNothing);
      expect(find.byType(FormMessage), findsNothing);
    });

    testWidgets('an expired session does not show the message', (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(
        buildTestApp(store: InMemorySessionStore(storedSession())),
      );
      await tester.pumpAndSettle();

      _controller(tester).expire();
      await tester.pumpAndSettle();

      expect(find.text('Masuk ke Niscala'), findsOneWidget);
      expect(find.text(_notice), findsNothing);
    });
  });
}

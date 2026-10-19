import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/theme.dart';

import '../features/auth/ui/auth_ui_helpers.dart';
import '../features/rooms/ui/room_ui_helpers.dart';
import '../helpers/fakes.dart';

double _titleLeft(WidgetTester tester, String title) => tester
    .getTopLeft(
      find.descendant(of: find.byType(AppBar), matching: find.text(title)),
    )
    .dx;

TextStyle _styleOf(WidgetTester tester, String text) => tester
    .widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text(text),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    )
    .style;

void main() {
  group('app bar', () {
    test('keeps its actions off the right edge', () {
      final padding = buildTheme().appBarTheme.actionsPadding;
      expect(
        padding?.resolve(TextDirection.ltr).right,
        greaterThanOrEqualTo(8),
      );
    });

    testWidgets('uses a chevron for the back button', (tester) async {
      await pumpRoomApp(
        tester,
        FakeRoomRepository(rooms: [makeRoom()]),
        path: '/properti/p1/kamar/r1',
      );
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.chevron_left),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a title without a back button keeps the screen gutter', (
      tester,
    ) async {
      await pumpVerify(tester, FakeAuthRepository());
      expect(_titleLeft(tester, 'Verifikasi email'), greaterThanOrEqualTo(16));
    });

    testWidgets('the room detail action stays inside the screen', (
      tester,
    ) async {
      await pumpRoomApp(
        tester,
        FakeRoomRepository(rooms: [makeRoom()]),
        path: '/properti/p1/kamar/r1',
      );
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final action = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Ubah'),
      );
      expect(tester.getRect(action).right, lessThanOrEqualTo(width - 8));
    });
  });

  group('forms', () {
    testWidgets('the show password label is 14 semibold', (tester) async {
      await pumpRegister(tester, FakeAuthRepository());
      final style = _styleOf(tester, 'Tampilkan kata sandi');
      expect(style.fontSize, 14);
      expect(style.fontWeight, FontWeight.w600);
    });

    testWidgets('the strength line is a small muted caption', (tester) async {
      await pumpRegister(tester, FakeAuthRepository());
      final style = _styleOf(
        tester,
        'Kekuatan kata sandi akan muncul saat Anda mengetik.',
      );
      expect(style.fontSize, 12);
    });

    testWidgets('the login logo has room above it', (tester) async {
      await pumpLogin(tester, FakeAuthRepository());
      expect(tester.getTopLeft(find.text('N')).dy, greaterThanOrEqualTo(48));
    });
  });
}

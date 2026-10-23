import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/rent_bills/data/receipt_picker.dart';
import 'package:niscala/features/rent_bills/ui/tenant_payments_screen.dart';
import 'package:niscala/features/rent_bills/ui/upload_receipt_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'rent_bill_ui_helpers.dart';

const _camera = 'Ambil dari kamera';
const _gallery = 'Pilih dari galeri';
const _send = 'Kirim Bukti';
const _chooseFirst = 'Pilih bukti transfer terlebih dahulu.';
const _cashHint = 'Bayar tunai ke pengelola kost';
const _sentMessage = 'Bukti transfer terkirim.';

final _typeError = errorMessage('RECEIPT_TYPE_INVALID');
final _sizeError = errorMessage('RECEIPT_TOO_LARGE');

({FakeRentBillRepository repo, FakeReceiptPicker picker}) _setup({
  List<RentBill>? bills,
}) => (
  repo: FakeRentBillRepository(bills: bills ?? sampleBills()),
  picker: FakeReceiptPicker(),
);

Future<void> _open(
  WidgetTester tester,
  ({FakeRentBillRepository repo, FakeReceiptPicker picker}) s, {
  String id = 'b1',
  bool largeText = false,
  bool settle = true,
}) => pumpRentBillApp(
  tester,
  s.repo,
  picker: s.picker,
  path: uploadPath(id),
  largeText: largeText,
  settle: settle,
);

Future<void> _pick(
  WidgetTester tester,
  FakeReceiptPicker picker,
  ReceiptFile? file, {
  String button = _gallery,
}) async {
  picker.queue.add(file);
  await tapVisible(tester, find.text(button));
}

Future<void> _submit(WidgetTester tester) =>
    tapVisible(tester, find.text(_send));

void main() {
  group('layout', () {
    testWidgets('is titled Unggah Bukti and shows the bill', (tester) async {
      await _open(tester, _setup());

      expect(find.byType(UploadReceiptScreen), findsOneWidget);
      expect(appBarTitle('Unggah Bukti'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Rp800.000'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Jatuh tempo'), findsAtLeastNWidgets(1));
      expect(find.textContaining('5 Nov 2026'), findsAtLeastNWidgets(1));
    });

    testWidgets('loads the bill by its id', (tester) async {
      final s = _setup();
      await _open(tester, s, id: 'b3');

      expect(s.repo.calls, contains('get:b3'));
    });

    testWidgets('shows the bank account of the property', (tester) async {
      await _open(tester, _setup());

      expect(find.textContaining('BCA'), findsAtLeastNWidgets(1));
      expect(find.textContaining('1234567890'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Siti Pemilik'), findsAtLeastNWidgets(1));
    });

    testWidgets('offers the camera, the gallery and sending', (tester) async {
      await _open(tester, _setup());

      expect(find.text(_camera), findsOneWidget);
      expect(find.text(_gallery), findsOneWidget);
      expect(find.text(_send), findsOneWidget);
      for (final label in [_camera, _gallery, _send]) {
        expectTargetSize(tester, label);
      }
    });

    testWidgets('puts the send button in a pinned footer', (tester) async {
      await _open(tester, _setup());

      expectPinnedFooter(tester, _send);
    });

    testWidgets('starts without a field error', (tester) async {
      await _open(tester, _setup());

      expect(find.text(_chooseFirst), findsNothing);
      expect(find.text(_typeError), findsNothing);
      expect(find.text(_sizeError), findsNothing);
    });

    testWidgets('opening the screen sends nothing', (tester) async {
      final s = _setup();
      await _open(tester, s);

      expect(s.repo.uploadCalls, 0);
      expect(s.picker.requested, isEmpty);
    });

    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final s = _setup();
      s.repo.getScript.gate = Completer<void>();
      await _open(tester, s, settle: false);

      expectLoading(tester);
      expect(find.text(_send), findsNothing);
    });
  });

  group('copy', () {
    testWidgets('copies the account number as plain digits', (tester) async {
      final copied = captureClipboard(tester);
      await _open(tester, _setup());

      await tapVisible(tester, find.text('Salin nomor rekening'));

      expect(copied, ['1234567890']);
    });

    testWidgets('copies the amount as plain digits', (tester) async {
      final copied = captureClipboard(tester);
      await _open(tester, _setup());

      await tapVisible(tester, find.text('Salin jumlah'));

      expect(copied, ['800000']);
    });

    testWidgets('the copy buttons are at least 48 dp', (tester) async {
      await _open(tester, _setup());

      expectTargetSize(tester, 'Salin nomor rekening');
      expectTargetSize(tester, 'Salin jumlah');
    });
  });

  group('picking', () {
    testWidgets('the gallery button asks for the gallery', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, null);

      expect(s.picker.requested, [ReceiptSource.gallery]);
    });

    testWidgets('the camera button asks for the camera', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, null, button: _camera);

      expect(s.picker.requested, [ReceiptSource.camera]);
    });

    testWidgets('cancelling shows no error and chooses nothing', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, null);

      expect(find.text(_typeError), findsNothing);
      expect(find.text(_sizeError), findsNothing);
      expect(find.text(_chooseFirst), findsNothing);
      await _submit(tester);
      expect(find.text(_chooseFirst), findsOneWidget);
      expect(s.repo.uploadCalls, 0);
    });

    testWidgets('shows the name of the chosen file', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, jpegFile(name: 'transfer-bca.jpg'));

      expect(find.text('transfer-bca.jpg'), findsOneWidget);
    });

    testWidgets('a photo from the camera is accepted', (tester) async {
      final s = _setup();
      await _open(tester, s);
      final photo = jpegFile(name: 'camera.jpg');

      await _pick(tester, s.picker, photo, button: _camera);
      await _submit(tester);

      expect(s.repo.uploaded.single.file.name, 'camera.jpg');
      expect(s.repo.uploaded.single.file.bytes, photo.bytes);
    });

    testWidgets('a later pick replaces the earlier one', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, jpegFile(name: 'satu.jpg'));
      await _pick(tester, s.picker, pngFile(name: 'dua.png'));
      await _submit(tester);

      expect(s.repo.uploaded.single.file.name, 'dua.png');
    });

    final accepted = <String, ReceiptFile Function()>{
      'a JPG file': jpegFile,
      'a PNG file': pngFile,
      'a JPEG with an upper case extension': () => jpegFile(name: 'FOTO.JPEG'),
      'a file of exactly 5 MB': () => jpegFile(length: maxReceiptBytes),
    };
    for (final entry in accepted.entries) {
      testWidgets('accepts ${entry.key}', (tester) async {
        final s = _setup();
        await _open(tester, s);

        await _pick(tester, s.picker, entry.value());

        expect(find.text(_typeError), findsNothing);
        expect(find.text(_sizeError), findsNothing);
      });
    }

    final wrongType = <String, ReceiptFile Function()>{
      'a PDF': pdfFile,
      'a PDF renamed to JPG': pdfNamedJpg,
      'a HEIC photo': heicFile,
      'a GIF image': gifFile,
    };
    for (final entry in wrongType.entries) {
      testWidgets('rejects ${entry.key} at once with the type message', (
        tester,
      ) async {
        final s = _setup();
        await _open(tester, s);

        await _pick(tester, s.picker, entry.value());

        expect(find.text(_typeError), findsOneWidget);
        expect(s.repo.uploadCalls, 0);
      });

      testWidgets('does not keep ${entry.key}', (tester) async {
        final s = _setup();
        await _open(tester, s);
        await _pick(tester, s.picker, entry.value());

        await _submit(tester);

        expect(s.repo.uploadCalls, 0);
        expect(find.text(_chooseFirst), findsOneWidget);
      });
    }

    testWidgets('rejects a file over 5 MB with the size message', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, jpegFile(length: maxReceiptBytes + 1));

      expect(find.text(_sizeError), findsOneWidget);
      expect(find.text(_typeError), findsNothing);
    });

    testWidgets('does not keep a file over 5 MB', (tester) async {
      final s = _setup();
      await _open(tester, s);
      await _pick(tester, s.picker, pngFile(length: maxReceiptBytes + 1));

      await _submit(tester);

      expect(s.repo.uploadCalls, 0);
    });

    testWidgets('a valid pick clears the earlier file error', (tester) async {
      final s = _setup();
      await _open(tester, s);
      await _pick(tester, s.picker, pdfFile());
      expect(find.text(_typeError), findsOneWidget);

      await _pick(tester, s.picker, jpegFile());

      expect(find.text(_typeError), findsNothing);
      await _submit(tester);
      expect(s.repo.uploadCalls, 1);
    });

    testWidgets('picking does not send by itself', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, jpegFile());

      expect(s.repo.uploadCalls, 0);
      expect(currentPath(tester), uploadPath('b1'));
    });
  });

  group('submit', () {
    testWidgets('without a file shows the choose file error', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await _submit(tester);

      expect(find.text(_chooseFirst), findsOneWidget);
      expect(s.repo.uploadCalls, 0);
      expect(currentPath(tester), uploadPath('b1'));
    });

    testWidgets('the send button is not disabled without a file', (
      tester,
    ) async {
      await _open(tester, _setup());

      expect(
        tester.widget<ButtonStyleButton>(buttonLabelled(_send)).onPressed,
        isNotNull,
      );
    });

    testWidgets('choosing a file clears the choose file error', (tester) async {
      final s = _setup();
      await _open(tester, s);
      await _submit(tester);

      await _pick(tester, s.picker, jpegFile());

      expect(find.text(_chooseFirst), findsNothing);
    });

    testWidgets('sends the chosen file for the bill', (tester) async {
      final s = _setup();
      await _open(tester, s);
      final file = pngFile(name: 'struk.png');

      await _pick(tester, s.picker, file);
      await _submit(tester);

      expect(s.repo.uploaded, hasLength(1));
      expect(s.repo.uploaded.single.id, 'b1');
      expect(s.repo.uploaded.single.file.name, 'struk.png');
      expect(s.repo.uploaded.single.file.bytes, file.bytes);
    });

    testWidgets('shows progress and disables the button while sending', (
      tester,
    ) async {
      final s = _setup();
      s.repo.uploadScript.gate = Completer<void>();
      await _open(tester, s);
      await _pick(tester, s.picker, jpegFile());

      await tapAndPump(tester, find.text(_send));

      expectBusy(tester);
      expect(currentPath(tester), uploadPath('b1'));
    });

    testWidgets('a second tap while sending does not send again', (
      tester,
    ) async {
      final s = _setup();
      final gate = Completer<void>();
      s.repo.uploadScript.gate = gate;
      await _open(tester, s);
      await _pick(tester, s.picker, jpegFile());

      await tapAndPump(tester, find.text(_send));
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();
      gate.complete();
      await tester.pumpAndSettle();

      expect(s.repo.uploadCalls, 1);
    });
  });

  group('success', () {
    Future<({FakeRentBillRepository repo, FakeReceiptPicker picker})> sent(
      WidgetTester tester,
    ) async {
      final s = _setup();
      await _open(tester, s);
      await _pick(tester, s.picker, jpegFile());
      await _submit(tester);
      return s;
    }

    testWidgets('goes back to the list', (tester) async {
      await sent(tester);

      expect(currentPath(tester), paymentsPath);
      expect(find.byType(TenantPaymentsScreen), findsOneWidget);
      expect(find.byType(UploadReceiptScreen), findsNothing);
    });

    testWidgets('confirms with a message', (tester) async {
      await sent(tester);

      expect(snackBar(_sentMessage), findsOneWidget);
    });

    testWidgets('the list shows the bill as awaiting verification', (
      tester,
    ) async {
      final s = await sent(tester);

      expect(s.repo.listCalls, greaterThanOrEqualTo(2));
      expect(
        inBill('Rp800.000', statusBadge('Menunggu Verifikasi')),
        findsOneWidget,
      );
      expect(inBill('Rp800.000', statusBadge('Belum Bayar')), findsNothing);
    });

    testWidgets('the list no longer offers the upload action for the bill', (
      tester,
    ) async {
      await sent(tester);

      expect(inBill('Rp800.000', find.text('Transfer sekarang')), findsNothing);
      expect(inBill('Rp800.000', find.text('Lihat bukti')), findsOneWidget);
    });

    testWidgets('a rejected bill becomes awaiting verification', (
      tester,
    ) async {
      final s = _setup(
        bills: [
          makeRentBill(
            status: PaymentStatus.rejected,
            rejectionReason: 'Foto buram.',
          ),
        ],
      );
      await _open(tester, s);
      await _pick(tester, s.picker, jpegFile());
      await _submit(tester);

      expect(statusBadge('Menunggu Verifikasi'), findsOneWidget);
      expect(statusBadge('Ditolak'), findsNothing);
      expect(find.textContaining('Foto buram.'), findsNothing);
    });
  });

  group('failure', () {
    Future<({FakeRentBillRepository repo, FakeReceiptPicker picker})> failing(
      WidgetTester tester,
      ApiFailure failure,
    ) async {
      final s = _setup();
      s.repo.uploadScript.queue.add(failure);
      await _open(tester, s);
      await _pick(tester, s.picker, jpegFile());
      await _submit(tester);
      return s;
    }

    testWidgets('a field error from the API shows next to the file', (
      tester,
    ) async {
      await failing(
        tester,
        const ApiFailure(code: 'VALIDATION_FAILED', field: 'file'),
      );

      expect(find.text('Bukti transfer tidak valid.'), findsOneWidget);
      expect(currentPath(tester), uploadPath('b1'));
    });

    for (final field in ['file', null]) {
      testWidgets(
        'a wrong type from the API shows its message (field $field)',
        (tester) async {
          await failing(
            tester,
            ApiFailure(code: 'RECEIPT_TYPE_INVALID', field: field),
          );

          expect(find.text(_typeError), findsOneWidget);
          expect(currentPath(tester), uploadPath('b1'));
        },
      );

      testWidgets(
        'a file too large from the API shows its message (field $field)',
        (tester) async {
          await failing(
            tester,
            ApiFailure(code: 'RECEIPT_TOO_LARGE', field: field),
          );

          expect(find.text(_sizeError), findsOneWidget);
          expect(currentPath(tester), uploadPath('b1'));
        },
      );
    }

    final banners = {
      'RENT_BILL_NOT_UPLOADABLE': errorMessage('RENT_BILL_NOT_UPLOADABLE'),
      'PROPERTY_BANK_ACCOUNT_MISSING': errorMessage(
        'PROPERTY_BANK_ACCOUNT_MISSING',
      ),
      'RENT_BILL_NOT_FOUND': 'Tagihan tidak ditemukan.',
      'NETWORK_ERROR': errorMessage('NETWORK_ERROR'),
      'SOMETHING_NEW': 'Terjadi kesalahan. Coba lagi.',
    };
    for (final entry in banners.entries) {
      testWidgets('${entry.key} shows its message in a banner', (tester) async {
        await failing(tester, ApiFailure(code: entry.key));

        expect(find.text(entry.value), findsOneWidget);
        expect(currentPath(tester), uploadPath('b1'));
      });

      testWidgets('the ${entry.key} banner is a live region that stays', (
        tester,
      ) async {
        await failing(tester, ApiFailure(code: entry.key));

        await tester.pump(const Duration(seconds: 30));

        expectLiveRegion(tester, entry.value);
      });
    }

    testWidgets('no failure shows the success message', (tester) async {
      await failing(tester, const ApiFailure.network());

      expect(snackBar(_sentMessage), findsNothing);
    });

    testWidgets('the button works again after a failure', (tester) async {
      await failing(tester, const ApiFailure.network());

      expect(busyButton(), findsNothing);
      expect(
        tester.widget<ButtonStyleButton>(buttonLabelled(_send)).onPressed,
        isNotNull,
      );
    });

    testWidgets('retrying after a failure sends the same file', (tester) async {
      final s = await failing(tester, const ApiFailure.network());

      await _submit(tester);

      expect(s.repo.uploadCalls, 2);
      expect(s.repo.uploaded.last.file.name, 'bukti.jpg');
      expect(currentPath(tester), paymentsPath);
      expect(snackBar(_sentMessage), findsOneWidget);
    });

    testWidgets('the banner goes away on the next submit', (tester) async {
      final s = await failing(tester, const ApiFailure.network());
      s.repo.uploadScript.queue.add(const ApiFailure(code: 'SOMETHING_NEW'));

      await _submit(tester);

      expect(find.text(errorMessage('NETWORK_ERROR')), findsNothing);
      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });
  });

  group('conflict', () {
    testWidgets('a conflict shows a banner and stays on the screen', (
      tester,
    ) async {
      final s = _setup();
      s.repo.uploadScript.queue.add(
        const ApiFailure(code: 'RENT_BILL_NOT_UPLOADABLE', statusCode: 409),
      );
      await _open(tester, s);
      await _pick(tester, s.picker, jpegFile());

      await _submit(tester);

      expect(
        find.text(errorMessage('RENT_BILL_NOT_UPLOADABLE')),
        findsOneWidget,
      );
      expect(currentPath(tester), uploadPath('b1'));
    });

    testWidgets('a conflict with an unknown code shows the generic message', (
      tester,
    ) async {
      final s = _setup();
      s.repo.uploadScript.queue.add(
        const ApiFailure(code: 'SOMETHING_NEW', statusCode: 409),
      );
      await _open(tester, s);
      await _pick(tester, s.picker, jpegFile());

      await _submit(tester);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('the list reloads when going back after a conflict', (
      tester,
    ) async {
      final s = _setup();
      await pumpRentBillApp(tester, s.repo, picker: s.picker);
      await tester.tap(find.text('Transfer sekarang'));
      await tester.pumpAndSettle();
      final before = s.repo.listCalls;
      s.repo.uploadScript.queue.add(
        const ApiFailure(code: 'RENT_BILL_NOT_UPLOADABLE', statusCode: 409),
      );
      await _pick(tester, s.picker, jpegFile());
      await _submit(tester);
      s.repo.bills[0] = makeRentBill(
        id: 'b1',
        status: PaymentStatus.awaitingVerification,
      );

      await pressBack(tester);

      expect(s.repo.listCalls, greaterThan(before));
      expect(
        inBill('Rp800.000', statusBadge('Menunggu Verifikasi')),
        findsOneWidget,
      );
    });
  });

  group('bill that cannot be uploaded to', () {
    final cases = <String, RentBill Function()>{
      'an overdue bill of an earlier period': () =>
          makeRentBill(daysOverdue: 12, isCurrent: false),
      'a bill of a property without a bank account': () =>
          makeRentBill(withoutBankAccount: true),
    };
    for (final entry in cases.entries) {
      testWidgets('${entry.key} hides the transfer and upload actions', (
        tester,
      ) async {
        await _open(tester, _setup(bills: [entry.value()]));

        for (final label in [
          _camera,
          _gallery,
          _send,
          'Salin nomor rekening',
        ]) {
          expect(find.text(label), findsNothing, reason: label);
        }
      });

      testWidgets('${entry.key} shows the amount and tells to pay cash', (
        tester,
      ) async {
        await _open(tester, _setup(bills: [entry.value()]));

        expect(find.text('Rp800.000'), findsAtLeastNWidgets(1));
        expect(find.textContaining(_cashHint), findsAtLeastNWidgets(1));
      });
    }

    testWidgets('a bill that can be uploaded to has no cash hint', (
      tester,
    ) async {
      await _open(tester, _setup());

      expect(find.textContaining(_cashHint), findsNothing);
    });
  });

  group('load failure', () {
    testWidgets('a missing bill shows its message and a retry', (tester) async {
      await _open(tester, _setup(), id: 'nope');

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Tagihan tidak ditemukan.'), findsOneWidget);
      expect(find.text(_send), findsNothing);
    });

    testWidgets('a network failure shows its message', (tester) async {
      final s = _setup();
      s.repo.getScript.always = const ApiFailure.network();
      await _open(tester, s);

      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
    });

    testWidgets('Coba lagi loads the bill again', (tester) async {
      final s = _setup();
      s.repo.getScript.queue.add(const ApiFailure.network());
      await _open(tester, s);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(s.repo.getCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text(_send), findsOneWidget);
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'initially': (tester, large) => _open(tester, _setup(), largeText: large),
      'with a chosen file': (tester, large) async {
        final s = _setup();
        await _open(tester, s, largeText: large);
        await _pick(tester, s.picker, jpegFile(name: 'transfer-bca.jpg'));
      },
      'with a choose file error': (tester, large) async {
        await _open(tester, _setup(), largeText: large);
        await _submit(tester);
      },
      'with a type error': (tester, large) async {
        final s = _setup();
        await _open(tester, s, largeText: large);
        await _pick(tester, s.picker, pdfFile());
      },
      'with a banner': (tester, large) async {
        final s = _setup();
        s.repo.uploadScript.queue.add(
          const ApiFailure(code: 'RENT_BILL_NOT_UPLOADABLE', statusCode: 409),
        );
        await _open(tester, s, largeText: large);
        await _pick(tester, s.picker, jpegFile());
        await _submit(tester);
      },
      'for a bill without bank account': (tester, large) => _open(
        tester,
        _setup(bills: [makeRentBill(withoutBankAccount: true)]),
        largeText: large,
      ),
      'for an overdue bill': (tester, large) => _open(
        tester,
        _setup(bills: [makeRentBill(daysOverdue: 12, isCurrent: false)]),
        largeText: large,
      ),
      'when the bill failed to load': (tester, large) {
        final s = _setup();
        s.repo.getScript.always = const ApiFailure.network();
        return _open(tester, s, largeText: large);
      },
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines ${entry.key}', (tester) async {
        await entry.value(tester, false);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size ${entry.key}', (tester) async {
        await entry.value(tester, true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines while sending', (tester) async {
      final s = _setup();
      s.repo.uploadScript.gate = Completer<void>();
      await _open(tester, s);
      await _pick(tester, s.picker, jpegFile());
      await tapAndPump(tester, find.text(_send));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while loading', (tester) async {
      final s = _setup();
      s.repo.getScript.gate = Completer<void>();
      await _open(tester, s, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });
  });
}

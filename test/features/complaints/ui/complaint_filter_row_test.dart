import 'package:flutter_test/flutter_test.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/filter_row.dart';
import 'complaint_ui_helpers.dart';

FakeComplaintRepository _repo() => FakeComplaintRepository(
  complaints: [
    makeComplaint(id: 'c1', description: 'Lampu kamar sering mati.'),
    makeComplaint(
      id: 'c2',
      description: 'Keran bocor.',
      status: ComplaintStatus.inProgress,
    ),
    makeComplaint(
      id: 'c3',
      description: 'Atap bocor.',
      status: ComplaintStatus.done,
    ),
  ],
);

void main() {
  group('management complaint list', () {
    defineFilterRowTests(
      pump: (tester, {bool largeText = false}) => pumpComplaintApp(
        tester,
        _repo(),
        role: UserRole.owner,
        largeText: largeText,
      ),
      labels: const ['Semua', 'Baru', 'Diproses', 'Selesai'],
      selected: 'Semua',
      last: 'Selesai',
      overflowsAtLargeText: true,
    );
  });

  group('tenant complaint list', () {
    defineFilterRowTests(
      pump: (tester, {bool largeText = false}) => pumpComplaintApp(
        tester,
        _repo(),
        role: UserRole.tenant,
        largeText: largeText,
      ),
      labels: const ['Aktif', 'Selesai'],
      selected: 'Aktif',
      last: 'Selesai',
      overflowsAtLargeText: false,
    );
  });
}

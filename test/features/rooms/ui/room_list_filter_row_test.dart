import '../../../helpers/fakes.dart';
import '../../../helpers/filter_row.dart';
import 'room_ui_helpers.dart';

void main() {
  defineFilterRowTests(
    pump: (tester, {bool largeText = false}) => pumpRoomApp(
      tester,
      FakeRoomRepository(
        rooms: [
          occupiedRoom(id: 'r1', number: '08'),
          vacantRoom(id: 'r2'),
        ],
      ),
      largeText: largeText,
    ),
    labels: const ['Semua', 'Terisi', 'Kosong'],
    selected: 'Semua',
    last: 'Kosong',
    overflowsAtLargeText: false,
  );
}

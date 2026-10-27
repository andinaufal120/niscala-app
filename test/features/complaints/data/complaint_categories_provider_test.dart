import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';

import '../../../helpers/fakes.dart';

ProviderContainer _container(FakeComplaintRepository repo) {
  final container = ProviderContainer(
    overrides: [complaintRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('complaintCategoriesProvider', () {
    test('loads the categories of the repository', () async {
      final repo = FakeComplaintRepository()
        ..categoryList = ['Listrik', 'Furnitur'];
      final container = _container(repo);

      final categories = await container.read(
        complaintCategoriesProvider.future,
      );

      expect(categories, ['Listrik', 'Furnitur']);
      expect(repo.categoriesCalls, 1);
    });

    test('fetches once however often it is read', () async {
      final repo = FakeComplaintRepository();
      final container = _container(repo);

      await container.read(complaintCategoriesProvider.future);
      await container.read(complaintCategoriesProvider.future);

      expect(repo.categoriesCalls, 1);
    });

    test('exposes the failure of the repository', () async {
      final repo = FakeComplaintRepository()
        ..categoriesScript.always = const ApiFailure.network();
      final container = _container(repo);

      await expectLater(
        container.read(complaintCategoriesProvider.future),
        throwsA(isA<ApiFailure>()),
      );
    });

    test('does not retry a failure in the background', () async {
      final repo = FakeComplaintRepository()
        ..categoriesScript.always = const ApiFailure.network();
      final container = _container(repo);
      container.listen(complaintCategoriesProvider, (_, _) {});

      await expectLater(
        container.read(complaintCategoriesProvider.future),
        throwsA(isA<ApiFailure>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(repo.categoriesCalls, 1);
    });

    test('fetches again after it is invalidated', () async {
      final repo = FakeComplaintRepository();
      final container = _container(repo);
      await container.read(complaintCategoriesProvider.future);

      container.invalidate(complaintCategoriesProvider);
      await container.read(complaintCategoriesProvider.future);

      expect(repo.categoriesCalls, 2);
    });
  });
}

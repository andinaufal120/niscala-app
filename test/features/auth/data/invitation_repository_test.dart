import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/auth/data/invitation_repository.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

http.Response _ok(Object body) =>
    http.Response(jsonEncode(body), 200, headers: _json);

http.Response _error(int status, String code, {String? field}) => http.Response(
  jsonEncode({'code': code, 'field': field, 'message': 'English text'}),
  status,
  headers: _json,
);

Map<String, Object?> _previewJson({
  String status = 'valid',
  String role = 'tenant',
  String name = 'Budi Santoso',
  String? roomNumber = '08',
  bool emergencyContactsRequired = true,
  List<Map<String, String>>? properties,
}) => {
  'status': status,
  'role': role,
  'name': name,
  'inviterName': 'Siti Pemilik',
  'roomNumber': roomNumber,
  'emergencyContactsRequired': emergencyContactsRequired,
  'expiresAt': '2026-10-25T12:00:00Z',
  'properties':
      properties ??
      [
        {'name': 'Kos Melati', 'address': 'Jl. Melati 1, Bandung'},
      ],
};

class _Harness {
  _Harness(http.Response Function(http.Request request) respond) {
    _build(
      MockClient((request) async {
        requests.add(request);
        return respond(request);
      }),
    );
  }

  _Harness.failing(Object error) {
    _build(
      MockClient((request) async {
        requests.add(request);
        throw error;
      }),
    );
  }

  void _build(http.Client client) {
    final apiClient = ApiClient(basePath: 'http://api.test')..client = client;
    repository = ApiInvitationRepository(
      invitations: InvitationsApi(apiClient),
      device: () async => DeviceInfo(name: 'Pixel 8', platform: 'android'),
    );
  }

  final requests = <http.Request>[];
  late final ApiInvitationRepository repository;

  http.Request get request => requests.single;
  Map<String, dynamic> get body =>
      jsonDecode(request.body) as Map<String, dynamic>;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

Future<AuthSession> _activate(
  _Harness h, {
  List<EmergencyContact>? emergencyContacts,
}) => h.repository.activateWithPassword(
  token: 'abc123',
  name: 'Budi Santoso',
  email: 'budi@example.com',
  password: ' kopi tubruk pagi ',
  emergencyContacts: emergencyContacts,
);

void main() {
  group('preview', () {
    test('posts the token and returns the preview', () async {
      final h = _Harness((_) => _ok(_previewJson()));

      final result = await h.repository.preview('abc123');

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/invitations/previews');
      expect(h.body, {'token': 'abc123'});
      expect(result.status, InvitationLinkStatus.valid);
      expect(result.role, InvitationRole.tenant);
      expect(result.name, 'Budi Santoso');
      expect(result.inviterName, 'Siti Pemilik');
      expect(result.roomNumber, '08');
      expect(result.emergencyContactsRequired, isTrue);
      expect(result.properties.single.name, 'Kos Melati');
    });

    test('returns a manager preview without a room', () async {
      final h = _Harness(
        (_) => _ok(
          _previewJson(
            role: 'manager',
            roomNumber: null,
            emergencyContactsRequired: false,
            properties: [
              {'name': 'Kos Melati', 'address': 'Jl. Melati 1'},
              {'name': 'Kos Mawar', 'address': 'Jl. Mawar 2'},
            ],
          ),
        ),
      );

      final result = await h.repository.preview('abc123');

      expect(result.role, InvitationRole.manager);
      expect(result.roomNumber, isNull);
      expect(result.properties.map((p) => p.name), ['Kos Melati', 'Kos Mawar']);
    });

    for (final entry in {
      'expired': InvitationLinkStatus.expired,
      'used': InvitationLinkStatus.used,
    }.entries) {
      test(
        'returns a ${entry.key} invitation as a preview, not a failure',
        () async {
          final h = _Harness((_) => _ok(_previewJson(status: entry.key)));

          final result = await h.repository.preview('abc123');

          expect(result.status, entry.value);
        },
      );
    }

    test('converts a not found response to an ApiFailure', () async {
      final h = _Harness((_) => _error(404, 'INVITATION_NOT_FOUND'));

      await expectLater(
        h.repository.preview('nope'),
        throwsA(_failure('INVITATION_NOT_FOUND', status: 404)),
      );
    });

    test('keeps the code, field and status of a validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'token'),
      );

      await expectLater(
        h.repository.preview(''),
        throwsA(_failure('VALIDATION_FAILED', field: 'token', status: 422)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.preview('abc123'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.preview('abc123'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.preview('abc123'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('activateWithPassword', () {
    test(
      'posts the sign-up data and the device and returns the session',
      () async {
        final session = authSessionFor(UserRole.tenant, emailVerified: false);
        final h = _Harness((_) => _ok(session.toJson()));

        final result = await _activate(h);

        expect(h.request.method, 'POST');
        expect(h.request.url.path, '/invitations/activations/password');
        expect(h.body['token'], 'abc123');
        expect(h.body['name'], 'Budi Santoso');
        expect(h.body['email'], 'budi@example.com');
        expect(h.body['password'], ' kopi tubruk pagi ');
        expect(h.body['device'], {'name': 'Pixel 8', 'platform': 'android'});
        expect(result.accessToken, session.accessToken);
        expect(result.refreshToken, session.refreshToken);
        expect(result.account.role, UserRole.tenant);
        expect(result.account.emailVerified, isFalse);
      },
    );

    test('sends no emergency contacts when none are given', () async {
      final h = _Harness((_) => _ok(authSessionFor(UserRole.tenant).toJson()));

      await _activate(h);

      expect(h.body['emergencyContacts'], isNull);
    });

    test('sends the emergency contacts when given', () async {
      final h = _Harness((_) => _ok(authSessionFor(UserRole.tenant).toJson()));

      await _activate(
        h,
        emergencyContacts: [
          EmergencyContact(
            name: 'Ibu Budi',
            relationship: 'Ibu',
            phone: '081255204471',
          ),
          EmergencyContact(
            name: 'Adi',
            relationship: 'Kakak',
            phone: '081311112222',
          ),
        ],
      );

      expect(h.body['emergencyContacts'], [
        {'name': 'Ibu Budi', 'relationship': 'Ibu', 'phone': '081255204471'},
        {'name': 'Adi', 'relationship': 'Kakak', 'phone': '081311112222'},
      ]);
    });

    test('keeps the code, field and status of a validation error', () async {
      final h = _Harness(
        (_) => _error(409, 'EMAIL_ALREADY_REGISTERED', field: 'email'),
      );

      await expectLater(
        _activate(h),
        throwsA(
          _failure('EMAIL_ALREADY_REGISTERED', field: 'email', status: 409),
        ),
      );
    });

    test('keeps the code of a common password error', () async {
      final h = _Harness(
        (_) => _error(422, 'PASSWORD_TOO_COMMON', field: 'password'),
      );

      await expectLater(
        _activate(h),
        throwsA(
          _failure('PASSWORD_TOO_COMMON', field: 'password', status: 422),
        ),
      );
    });

    test('converts an error response without a field', () async {
      final h = _Harness((_) => _error(409, 'INVITATION_ALREADY_USED'));

      await expectLater(
        _activate(h),
        throwsA(_failure('INVITATION_ALREADY_USED', status: 409)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(_activate(h), throwsA(_failure('NETWORK_ERROR')));
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(_activate(h), throwsA(_failure('NETWORK_ERROR')));
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 503));

      await expectLater(
        _activate(h),
        throwsA(_failure('INTERNAL_ERROR', status: 503)),
      );
    });
  });
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala_api/api.dart';

/// What the fake backend knows about one user. The user is recognised by the
/// bearer token, which starts with [tokenPrefix].
class BackendUser {
  BackendUser({
    required this.tokenPrefix,
    required this.account,
    List<ComplaintSummary>? complaints,
    List<PropertySummary>? properties,
    List<CurrentLease>? leases,
  }) : complaints = complaints ?? [],
       properties = properties ?? [],
       leases = leases ?? [];

  final String tokenPrefix;
  final Account account;
  List<ComplaintSummary> complaints;
  List<PropertySummary> properties;
  List<CurrentLease> leases;
}

/// A request that reached the fake backend.
typedef BackendRequest = ({String method, String path, String? token});

/// A [ComplaintSummary] with sensible defaults, for a fake backend.
ComplaintSummary makeComplaintSummary({
  String id = 'c1',
  String description = 'Keran air di kamar mandi bocor sejak kemarin.',
  String tenantName = 'Budi Santoso',
}) => ComplaintSummary(
  id: id,
  description: description,
  status: ComplaintStatus.new_,
  classificationWithheld: false,
  createdAt: DateTime.utc(2026, 10, 18, 12),
  hasPhoto: false,
  property: PropertyRef(id: 'p1', name: 'Kos Melati'),
  room: RoomRef(id: 'r1', number: '08'),
  tenantName: tenantName,
);

/// A [PropertySummary] with sensible defaults, for a fake backend.
PropertySummary makePropertySummary({
  String id = 'p1',
  String name = 'Kos Melati',
}) => PropertySummary(
  id: id,
  name: name,
  address: 'Jl. Melati 1, Bandung',
  roomCount: 10,
  occupiedRoomCount: 4,
  managers: const [],
  editable: true,
);

/// An [Account] of [role] with a name, for a fake backend.
Account makeBackendAccount(
  UserRole role, {
  String name = 'Budi',
  String id = 'a1',
}) => Account(
  email: '$id@example.com',
  emailVerified: true,
  googleEmail: null,
  hasPassword: true,
  id: id,
  name: name,
  role: role,
);

/// An HTTP backend that answers each request from the data of the user whose
/// bearer token it carries, and records every request.
///
/// It serves the lists of complaints, properties and leases, the account and
/// the (always empty) active bills. A request without a known token, and any
/// other path, gets a 404 without a token being treated as expired.
class FakeBackend {
  FakeBackend(List<BackendUser> users) : users = List.of(users) {
    client = MockClient(_handle);
  }

  final List<BackendUser> users;
  final requests = <BackendRequest>[];
  late final http.Client client;

  /// How many requests went to [path], whatever the method or the user.
  int requestsTo(String path) => requests.where((r) => r.path == path).length;

  /// The tokens of the requests to [path], in order.
  List<String?> tokensOf(String path) => [
    for (final r in requests)
      if (r.path == path) r.token,
  ];

  Future<http.Response> _handle(http.Request request) async {
    final token = _bearerOf(request);
    requests.add((
      method: request.method,
      path: request.url.path,
      token: token,
    ));
    final user = token == null
        ? null
        : users.where((u) => token.startsWith(u.tokenPrefix)).firstOrNull;
    if (user == null) return _json(404, {'code': 'NOT_FOUND'});
    final path = request.url.path;
    final body = switch (path) {
      '/complaints' => {'items': user.complaints},
      '/properties' => {'items': user.properties},
      '/me/leases' => {'items': user.leases},
      '/me' => user.account,
      '/rent-bills' => {'items': <Object>[]},
      _ when path.startsWith('/complaints/') => _complaintDetail(user, path),
      _ => null,
    };
    return body == null ? _json(404, {'code': 'NOT_FOUND'}) : _json(200, body);
  }

  /// The detail of one of the complaints of [user], without status changes.
  Complaint? _complaintDetail(BackendUser user, String path) {
    final id = path.substring('/complaints/'.length);
    final summary = user.complaints.where((c) => c.id == id).firstOrNull;
    if (summary == null) return null;
    return Complaint(
      id: summary.id,
      description: summary.description,
      status: summary.status,
      classification: summary.classification,
      classificationState: summary.classificationState,
      classificationWithheld: summary.classificationWithheld,
      createdAt: summary.createdAt,
      hasPhoto: summary.hasPhoto,
      property: summary.property,
      room: summary.room,
      statusChanges: const [],
      tenantName: summary.tenantName,
    );
  }

  String? _bearerOf(http.Request request) {
    for (final entry in request.headers.entries) {
      if (entry.key.toLowerCase() == 'authorization') {
        return entry.value.replaceFirst('Bearer ', '');
      }
    }
    return null;
  }

  http.Response _json(int status, Object body) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

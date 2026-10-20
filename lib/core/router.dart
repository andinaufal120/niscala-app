import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/shell/app_shell.dart';
import 'package:niscala/core/shell/fading_tab_stack.dart';
import 'package:niscala/core/widgets/loading_screen.dart';
import 'package:niscala/core/widgets/placeholder_screen.dart';
import 'package:niscala/features/auth/ui/activation_screen.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/auth/ui/register_owner_screen.dart';
import 'package:niscala/features/auth/ui/verify_email_screen.dart';
import 'package:niscala/features/complaints/ui/complaint_form_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_list_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_list_screen.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala/features/properties/ui/property_form_screen.dart';
import 'package:niscala/features/properties/ui/property_list_screen.dart';
import 'package:niscala/features/rooms/ui/room_detail_screen.dart';
import 'package:niscala/features/rooms/ui/room_form_screen.dart';
import 'package:niscala/features/rooms/ui/room_list_screen.dart';
import 'package:niscala/features/tenants/ui/invitation_qr_screen.dart';
import 'package:niscala/features/tenants/ui/invitation_share_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_detail_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_form_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_list_screen.dart';
import 'package:niscala_api/api.dart';

const _loading = '/memuat';
const _signIn = '/masuk';
const _verifyEmail = '/verifikasi-email';
const _admin = '/admin';
const _managementHome = '/beranda';
const _tenantHome = '/penyewa/beranda';
const _propertyRoot = '/properti';
const _managementComplaints = '/keluhan';
const _tenantComplaints = '/penyewa/keluhan';

const _signedOutRoutes = {_signIn, '/daftar', '/aktivasi'};
const _managementRoutes = {_managementHome, '/keluhan', '/pembayaran', '/akun'};
const _tenantRoutes = {
  _tenantHome,
  '/penyewa/keluhan',
  '/penyewa/pembayaran',
  '/penyewa/akun',
};

/// [root] itself or any location below it.
bool _isUnder(String location, String root) =>
    location == root || location.startsWith('$root/');

/// Where [location] must be redirected for the session, or null to stay.
String? redirectFor(SessionState session, String location) {
  switch (session) {
    case SessionLoading():
      return location == _loading ? null : _loading;
    case SignedOut():
      return _signedOutRoutes.contains(location) ? null : _signIn;
    case SignedIn(emailVerified: false):
      return location == _verifyEmail ? null : _verifyEmail;
    case SignedIn(:final role):
      if (role == UserRole.tenant) {
        final allowed =
            _tenantRoutes.contains(location) ||
            _isUnder(location, _tenantComplaints);
        return allowed ? null : _tenantHome;
      }
      if (role == UserRole.admin) {
        return location == _admin ? null : _admin;
      }
      final allowed =
          _managementRoutes.contains(location) ||
          _isUnder(location, _propertyRoot) ||
          _isUnder(location, _managementComplaints);
      return allowed ? null : _managementHome;
  }
}

/// Cross-fades the tabs of a shell when the tab changes.
Widget _fadingTabs(
  BuildContext context,
  StatefulNavigationShell navigationShell,
  List<Widget> children,
) => FadingTabStack(index: navigationShell.currentIndex, children: children);

GoRoute _screen(String path, Widget screen) =>
    GoRoute(path: path, builder: (context, state) => screen);

GoRoute _placeholder(String path, String title) =>
    _screen(path, PlaceholderScreen(title: title));

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);

NavigationDestination _tab(String label, IconData icon) =>
    NavigationDestination(icon: Icon(icon), label: label);

/// A tab whose list screen has child routes. The children sit under the list,
/// so the tab stays selected and Kembali returns to the list.
StatefulShellBranch _nestedBranch(
  String path,
  Widget screen,
  List<RouteBase> routes,
) => StatefulShellBranch(
  routes: [
    GoRoute(path: path, builder: (context, state) => screen, routes: routes),
  ],
);

/// The rooms of a property: the list, the add form, and one room with its edit
/// form. The add route comes before `:roomId` so it is not read as a room id.
List<RouteBase> _roomRoutes() => [
  GoRoute(
    path: 'kamar',
    builder: (context, state) =>
        RoomListScreen(propertyId: state.pathParameters['propertyId']!),
    routes: [
      GoRoute(
        path: 'tambah',
        builder: (context, state) =>
            RoomFormScreen(propertyId: state.pathParameters['propertyId']!),
      ),
      GoRoute(
        path: ':roomId',
        builder: (context, state) => RoomDetailScreen(
          propertyId: state.pathParameters['propertyId']!,
          roomId: state.pathParameters['roomId']!,
        ),
        routes: [
          GoRoute(
            path: 'ubah',
            builder: (context, state) => RoomFormScreen(
              propertyId: state.pathParameters['propertyId']!,
              roomId: state.pathParameters['roomId'],
            ),
          ),
        ],
      ),
    ],
  ),
];

/// The tenants of a property: the list, the add form, one tenant, and the
/// invitation screens of that tenant. The add route comes before `:tenantId`,
/// as for rooms.
List<RouteBase> _tenantScreenRoutes() => [
  GoRoute(
    path: 'penyewa',
    builder: (context, state) =>
        TenantListScreen(propertyId: state.pathParameters['propertyId']!),
    routes: [
      GoRoute(
        path: 'tambah',
        builder: (context, state) => TenantFormScreen(
          propertyId: state.pathParameters['propertyId']!,
          preselectedRoomId: state.uri.queryParameters['kamar'],
        ),
      ),
      GoRoute(
        path: ':tenantId',
        builder: (context, state) => TenantDetailScreen(
          propertyId: state.pathParameters['propertyId']!,
          tenantId: state.pathParameters['tenantId']!,
        ),
        routes: [
          GoRoute(
            path: 'undangan',
            builder: (context, state) => InvitationShareScreen(
              propertyId: state.pathParameters['propertyId']!,
              tenantId: state.pathParameters['tenantId']!,
              isNew: state.uri.queryParameters['baru'] == '1',
            ),
            routes: [
              GoRoute(
                path: 'qr',
                builder: (context, state) => InvitationQrScreen(
                  propertyId: state.pathParameters['propertyId']!,
                  tenantId: state.pathParameters['tenantId']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];

/// The Properti tab. The detail, form, room and tenant routes are children of
/// the list, so the tab stays selected and Kembali returns to the list.
StatefulShellBranch _propertiesBranch() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: _propertyRoot,
      builder: (context, state) => const PropertyListScreen(),
      routes: [
        GoRoute(
          path: 'tambah',
          builder: (context, state) => const PropertyFormScreen(),
        ),
        GoRoute(
          path: ':propertyId',
          builder: (context, state) => PropertyDetailScreen(
            propertyId: state.pathParameters['propertyId']!,
          ),
          routes: [
            GoRoute(
              path: 'ubah',
              builder: (context, state) => PropertyFormScreen(
                propertyId: state.pathParameters['propertyId'],
              ),
            ),
            ..._roomRoutes(),
            ..._tenantScreenRoutes(),
          ],
        ),
      ],
    ),
  ],
);

final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<SessionState>(
    ref.read(sessionControllerProvider),
  );
  ref.listen(sessionControllerProvider, (_, next) => session.value = next);
  ref.onDispose(session.dispose);

  final router = GoRouter(
    initialLocation: _loading,
    refreshListenable: session,
    redirect: (context, state) => redirectFor(session.value, state.uri.path),
    routes: [
      GoRoute(
        path: _loading,
        builder: (context, state) => const LoadingScreen(),
      ),
      _screen(_signIn, const LoginScreen()),
      _screen('/daftar', const RegisterOwnerScreen()),
      _screen('/aktivasi', const ActivationScreen()),
      _screen(_verifyEmail, const VerifyEmailScreen()),
      _placeholder(_admin, 'Admin'),
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(
          navigationShell: shell,
          destinations: [
            _tab('Beranda', Icons.home_outlined),
            _tab('Keluhan', Icons.build_outlined),
            _tab('Pembayaran', Icons.credit_card_outlined),
            _tab('Properti', Icons.apartment_outlined),
            _tab('Akun', Icons.person_outline),
          ],
        ),
        navigatorContainerBuilder: _fadingTabs,
        branches: [
          _branch(_managementHome, const PlaceholderScreen(title: 'Beranda')),
          _nestedBranch(
            _managementComplaints,
            const ManagementComplaintListScreen(),
            [
              GoRoute(
                path: ':complaintId',
                builder: (context, state) => ManagementComplaintDetailScreen(
                  complaintId: state.pathParameters['complaintId']!,
                ),
              ),
            ],
          ),
          _branch('/pembayaran', const PlaceholderScreen(title: 'Pembayaran')),
          _propertiesBranch(),
          _branch('/akun', const AccountScreen()),
        ],
      ),
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(
          navigationShell: shell,
          destinations: [
            _tab('Beranda', Icons.home_outlined),
            _tab('Keluhan', Icons.build_outlined),
            _tab('Pembayaran', Icons.credit_card_outlined),
            _tab('Akun', Icons.person_outline),
          ],
        ),
        navigatorContainerBuilder: _fadingTabs,
        branches: [
          _branch(_tenantHome, const PlaceholderScreen(title: 'Beranda')),
          _nestedBranch(_tenantComplaints, const TenantComplaintListScreen(), [
            // The form route comes before `:complaintId`, as for rooms.
            GoRoute(
              path: 'baru',
              builder: (context, state) => const ComplaintFormScreen(),
            ),
            GoRoute(
              path: ':complaintId',
              builder: (context, state) => TenantComplaintDetailScreen(
                complaintId: state.pathParameters['complaintId']!,
                submitted: state.uri.queryParameters['terkirim'] == '1',
              ),
            ),
          ]),
          _branch(
            '/penyewa/pembayaran',
            const PlaceholderScreen(title: 'Pembayaran'),
          ),
          _branch('/penyewa/akun', const AccountScreen()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/shell/app_shell.dart';
import 'package:niscala/core/shell/fading_tab_stack.dart';
import 'package:niscala/core/widgets/loading_screen.dart';
import 'package:niscala/core/widgets/placeholder_screen.dart';
import 'package:niscala/features/auth/ui/accept_invitation_screen.dart';
import 'package:niscala/features/auth/ui/activation_screen.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/auth/ui/register_owner_screen.dart';
import 'package:niscala/features/account/ui/active_sessions_screen.dart';
import 'package:niscala/features/account/ui/change_password_screen.dart';
import 'package:niscala/features/auth/ui/verify_email_screen.dart';
import 'package:niscala/features/complaints/ui/complaint_form_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_list_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_list_screen.dart';
import 'package:niscala/features/dashboard/ui/occupancy_dashboard_screen.dart';
import 'package:niscala/features/home/ui/tenant_home_screen.dart';
import 'package:niscala/features/managers/ui/manager_detail_screen.dart';
import 'package:niscala/features/managers/ui/manager_form_screen.dart';
import 'package:niscala/features/managers/ui/manager_invitation_qr_screen.dart';
import 'package:niscala/features/managers/ui/manager_invitation_share_screen.dart';
import 'package:niscala/features/managers/ui/manager_list_screen.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala/features/properties/ui/property_form_screen.dart';
import 'package:niscala/features/properties/ui/property_list_screen.dart';
import 'package:niscala/features/rent_bills/ui/receipt_view_screen.dart';
import 'package:niscala/features/rent_bills/ui/tenant_payments_screen.dart';
import 'package:niscala/features/rent_bills/ui/upload_receipt_screen.dart';
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
const _tenantPayments = '/penyewa/pembayaran';

/// The navigator of the whole app. Sub-pages are shown on it, above the tab
/// shell, so they cover the bottom navigation bar. Tab roots stay in the shell.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

const _signedOutRoutes = {_signIn, '/daftar', '/aktivasi'};
const _managementRoutes = {
  _managementHome,
  '/keluhan',
  '/pembayaran',
  '/akun',
  '/akun/perangkat',
  '/akun/kata-sandi',
  '/akun/undangan',
};
const _tenantRoutes = {
  _tenantHome,
  '/penyewa/keluhan',
  '/penyewa/akun',
  '/penyewa/akun/perangkat',
  '/penyewa/akun/kata-sandi',
};

/// [root] itself or any location below it.
bool _isUnder(String location, String root) =>
    location == root || location.startsWith('$root/');

/// The manager screens of a property, `/properti/:id/pengelola` and below. Only
/// the Owner manages managers.
bool _isManagerScreen(String location) {
  final segments = location.split('/');
  return segments.length > 3 &&
      segments[1] == 'properti' &&
      segments[3] == 'pengelola';
}

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
            _isUnder(location, _tenantComplaints) ||
            _isUnder(location, _tenantPayments);
        return allowed ? null : _tenantHome;
      }
      if (role == UserRole.admin) {
        return location == _admin ? null : _admin;
      }
      if (role == UserRole.manager && _isManagerScreen(location)) {
        return _managementHome;
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

/// A sub-page of a tab root. It is shown on the root navigator, so it covers
/// the shell and its bottom navigation bar. As a [MaterialPage] it takes the
/// page transition of the theme, so it slides in and out.
GoRoute _subPage({
  required String path,
  required Widget Function(BuildContext, GoRouterState) builder,
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  parentNavigatorKey: _rootNavigatorKey,
  pageBuilder: (context, state) =>
      MaterialPage<void>(key: state.pageKey, child: builder(context, state)),
  routes: routes,
);

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

/// The Akun tab of a role and its sub-pages. The tab reads the notice that a
/// sub-page passes with `extra`, such as the result of a password change.
StatefulShellBranch _accountBranch(String path, {bool showLease = false}) =>
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          builder: (context, state) => AccountScreen(
            showLease: showLease,
            notice: state.extra as String?,
          ),
          routes: [
            _subPage(
              path: 'perangkat',
              builder: (context, state) => const ActiveSessionsScreen(),
            ),
            _subPage(
              path: 'kata-sandi',
              builder: (context, state) => const ChangePasswordScreen(),
            ),
            _subPage(
              path: 'undangan',
              builder: (context, state) => const AcceptInvitationScreen(),
            ),
          ],
        ),
      ],
    );

/// The rooms of a property: the list, the add form, and one room with its edit
/// form. The add route comes before `:roomId` so it is not read as a room id.
List<RouteBase> _roomRoutes() => [
  _subPage(
    path: 'kamar',
    builder: (context, state) =>
        RoomListScreen(propertyId: state.pathParameters['propertyId']!),
    routes: [
      _subPage(
        path: 'tambah',
        builder: (context, state) =>
            RoomFormScreen(propertyId: state.pathParameters['propertyId']!),
      ),
      _subPage(
        path: ':roomId',
        builder: (context, state) => RoomDetailScreen(
          propertyId: state.pathParameters['propertyId']!,
          roomId: state.pathParameters['roomId']!,
        ),
        routes: [
          _subPage(
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
  _subPage(
    path: 'penyewa',
    builder: (context, state) =>
        TenantListScreen(propertyId: state.pathParameters['propertyId']!),
    routes: [
      _subPage(
        path: 'tambah',
        builder: (context, state) => TenantFormScreen(
          propertyId: state.pathParameters['propertyId']!,
          preselectedRoomId: state.uri.queryParameters['kamar'],
        ),
      ),
      _subPage(
        path: ':tenantId',
        builder: (context, state) => TenantDetailScreen(
          propertyId: state.pathParameters['propertyId']!,
          tenantId: state.pathParameters['tenantId']!,
        ),
        routes: [
          _subPage(
            path: 'undangan',
            builder: (context, state) => InvitationShareScreen(
              propertyId: state.pathParameters['propertyId']!,
              tenantId: state.pathParameters['tenantId']!,
              isNew: state.uri.queryParameters['baru'] == '1',
            ),
            routes: [
              _subPage(
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

/// The managers of a property (Owner only): the add form, the list, and one
/// manager with its edit form and invitation screens.
///
/// The add form is not nested under the list, so opening it does not load the
/// list; its Kembali goes back to the list explicitly. It comes first, so that
/// `pengelola/tambah` is not read as a manager id.
List<RouteBase> _managerScreenRoutes() => [
  _subPage(
    path: 'pengelola/tambah',
    builder: (context, state) =>
        ManagerFormScreen(propertyId: state.pathParameters['propertyId']!),
  ),
  _subPage(
    path: 'pengelola',
    builder: (context, state) =>
        ManagerListScreen(propertyId: state.pathParameters['propertyId']!),
    routes: [
      _subPage(
        path: ':managerId',
        builder: (context, state) => ManagerDetailScreen(
          propertyId: state.pathParameters['propertyId']!,
          managerId: state.pathParameters['managerId']!,
        ),
        routes: [
          _subPage(
            path: 'ubah',
            builder: (context, state) => ManagerFormScreen(
              propertyId: state.pathParameters['propertyId']!,
              managerId: state.pathParameters['managerId'],
            ),
          ),
          _subPage(
            path: 'undangan',
            builder: (context, state) => ManagerInvitationShareScreen(
              propertyId: state.pathParameters['propertyId']!,
              managerId: state.pathParameters['managerId']!,
              isNew: state.uri.queryParameters['baru'] == '1',
            ),
            routes: [
              _subPage(
                path: 'qr',
                builder: (context, state) => ManagerInvitationQrScreen(
                  propertyId: state.pathParameters['propertyId']!,
                  managerId: state.pathParameters['managerId']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];

/// The Properti tab. The list is the tab root; the add form, the detail and the
/// room, tenant and manager routes of a property are sub-pages shown above the
/// shell.
StatefulShellBranch _propertiesBranch() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: _propertyRoot,
      builder: (context, state) => const PropertyListScreen(),
      routes: [
        _subPage(
          path: 'tambah',
          builder: (context, state) => const PropertyFormScreen(),
        ),
        _subPage(
          path: ':propertyId',
          builder: (context, state) => PropertyDetailScreen(
            propertyId: state.pathParameters['propertyId']!,
          ),
          routes: [
            _subPage(
              path: 'ubah',
              builder: (context, state) => PropertyFormScreen(
                propertyId: state.pathParameters['propertyId'],
              ),
            ),
            ..._roomRoutes(),
            ..._tenantScreenRoutes(),
            ..._managerScreenRoutes(),
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
    navigatorKey: _rootNavigatorKey,
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
          _branch(_managementHome, const OccupancyDashboardScreen()),
          _nestedBranch(
            _managementComplaints,
            const ManagementComplaintListScreen(),
            [
              _subPage(
                path: ':complaintId',
                builder: (context, state) => ManagementComplaintDetailScreen(
                  complaintId: state.pathParameters['complaintId']!,
                ),
              ),
            ],
          ),
          _branch('/pembayaran', const PlaceholderScreen(title: 'Pembayaran')),
          _propertiesBranch(),
          _accountBranch('/akun'),
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
          _branch(_tenantHome, const TenantHomeScreen()),
          _nestedBranch(_tenantComplaints, const TenantComplaintListScreen(), [
            // The form route comes before `:complaintId`, as for rooms.
            _subPage(
              path: 'baru',
              builder: (context, state) => const ComplaintFormScreen(),
            ),
            _subPage(
              path: ':complaintId',
              builder: (context, state) => TenantComplaintDetailScreen(
                complaintId: state.pathParameters['complaintId']!,
                submitted: state.uri.queryParameters['terkirim'] == '1',
              ),
            ),
          ]),
          _nestedBranch(_tenantPayments, const TenantPaymentsScreen(), [
            _subPage(
              path: 'unggah/:id',
              builder: (context, state) =>
                  UploadReceiptScreen(billId: state.pathParameters['id']!),
            ),
            _subPage(
              path: 'bukti/:id',
              builder: (context, state) =>
                  ReceiptViewScreen(billId: state.pathParameters['id']!),
            ),
          ]),
          _accountBranch('/penyewa/akun', showLease: true),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/shell/app_shell.dart';
import 'package:niscala/core/widgets/loading_screen.dart';
import 'package:niscala/core/widgets/placeholder_screen.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/auth/ui/register_owner_screen.dart';
import 'package:niscala/features/auth/ui/verify_email_screen.dart';
import 'package:niscala_api/api.dart';

const _loading = '/memuat';
const _signIn = '/masuk';
const _verifyEmail = '/verifikasi-email';
const _admin = '/admin';
const _managementHome = '/beranda';
const _tenantHome = '/penyewa/beranda';

const _signedOutRoutes = {_signIn, '/daftar', '/aktivasi'};
const _managementRoutes = {
  _managementHome,
  '/keluhan',
  '/pembayaran',
  '/properti',
  '/akun',
};
const _tenantRoutes = {
  _tenantHome,
  '/penyewa/keluhan',
  '/penyewa/pembayaran',
  '/penyewa/akun',
};

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
      final (home, allowed) = role == UserRole.tenant
          ? (_tenantHome, _tenantRoutes)
          : role == UserRole.admin
          ? (_admin, const {_admin})
          : (_managementHome, _managementRoutes);
      return allowed.contains(location) ? null : home;
  }
}

GoRoute _screen(String path, Widget screen) =>
    GoRoute(path: path, builder: (context, state) => screen);

GoRoute _placeholder(String path, String title) =>
    _screen(path, PlaceholderScreen(title: title));

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);

NavigationDestination _tab(String label, IconData icon) =>
    NavigationDestination(icon: Icon(icon), label: label);

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
      _placeholder('/aktivasi', 'Aktivasi Akun'),
      _screen(_verifyEmail, const VerifyEmailScreen()),
      _placeholder(_admin, 'Admin'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(
          navigationShell: shell,
          destinations: [
            _tab('Beranda', Icons.home_outlined),
            _tab('Keluhan', Icons.report_problem_outlined),
            _tab('Pembayaran', Icons.payments_outlined),
            _tab('Properti', Icons.apartment_outlined),
            _tab('Akun', Icons.person_outline),
          ],
        ),
        branches: [
          _branch(_managementHome, const PlaceholderScreen(title: 'Beranda')),
          _branch('/keluhan', const PlaceholderScreen(title: 'Keluhan')),
          _branch('/pembayaran', const PlaceholderScreen(title: 'Pembayaran')),
          _branch('/properti', const PlaceholderScreen(title: 'Properti')),
          _branch('/akun', const AccountScreen()),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(
          navigationShell: shell,
          destinations: [
            _tab('Beranda', Icons.home_outlined),
            _tab('Keluhan', Icons.report_problem_outlined),
            _tab('Pembayaran', Icons.payments_outlined),
            _tab('Akun', Icons.person_outline),
          ],
        ),
        branches: [
          _branch(_tenantHome, const PlaceholderScreen(title: 'Beranda')),
          _branch(
            '/penyewa/keluhan',
            const PlaceholderScreen(title: 'Keluhan'),
          ),
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

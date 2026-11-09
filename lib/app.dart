import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/server_status.dart';
import 'package:niscala/core/push/push_coordinator.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala/core/widgets/server_status_banner.dart';

class NiscalaApp extends ConsumerStatefulWidget {
  const NiscalaApp({super.key});

  @override
  ConsumerState<NiscalaApp> createState() => _NiscalaAppState();
}

class _NiscalaAppState extends ConsumerState<NiscalaApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Started before the session is restored, so no session change is missed.
    ref.read(pushCoordinatorProvider);
    // Wakes the API while the user is still on the start-up screen.
    unawaited(ref.read(serverStatusProvider.notifier).check());
    ref.read(sessionControllerProvider.notifier).restore();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(ref.read(serverStatusProvider.notifier).check()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Niscala',
      theme: buildTheme(),
      locale: const Locale('id'),
      supportedLocales: const [Locale('id')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => ServerStatusBanner(child: child!),
    );
  }
}

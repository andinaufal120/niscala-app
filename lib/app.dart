import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/theme.dart';

class NiscalaApp extends ConsumerStatefulWidget {
  const NiscalaApp({super.key});

  @override
  ConsumerState<NiscalaApp> createState() => _NiscalaAppState();
}

class _NiscalaAppState extends ConsumerState<NiscalaApp> {
  @override
  void initState() {
    super.initState();
    ref.read(sessionControllerProvider.notifier).restore();
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
    );
  }
}

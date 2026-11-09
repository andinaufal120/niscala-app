import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/api/server_status.dart';

/// Shows a panel above [child] while the server cannot be reached, with a
/// button to check again. The child is never blocked: it keeps its place in
/// the tree, so its state survives the panel appearing and going away.
class ServerStatusBanner extends ConsumerWidget {
  const ServerStatusBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problem = ref.watch(serverStatusProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (problem == null)
          const SizedBox.shrink()
        else
          _Panel(
            problem: problem,
            onRetry: () =>
                unawaited(ref.read(serverStatusProvider.notifier).check()),
          ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: problem != null,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.problem, required this.onRetry});

  final ServerProblem problem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final message = switch (problem) {
      ServerProblem.noConnection => errorMessageFor(const ApiFailure.network()),
      ServerProblem.unavailable => serviceUnavailableMessage,
    };
    return Material(
      color: colors.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: colors.onErrorContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onErrorContainer,
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: onRetry,
                  child: const Text('Coba lagi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

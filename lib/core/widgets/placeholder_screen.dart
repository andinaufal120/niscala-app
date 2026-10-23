import 'package:flutter/material.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/screen_header.dart';

/// Stands in for a tab root that is not built yet.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(title: title),
          const Expanded(
            child: EmptyState(message: 'Fitur ini belum tersedia'),
          ),
        ],
      ),
    );
  }
}

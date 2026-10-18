import 'package:flutter/material.dart';
import 'package:niscala/core/widgets/empty_state.dart';

/// Stands in for a screen that is not built yet.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const EmptyState(message: 'Fitur ini belum tersedia'),
    );
  }
}

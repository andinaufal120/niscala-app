import 'package:flutter/material.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

bool isValidEmail(String email) => _emailPattern.hasMatch(email);

/// A scrolling form page. The credential fields share one autofill group.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key, this.appBar, required this.children});

  final PreferredSizeWidget? appBar;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

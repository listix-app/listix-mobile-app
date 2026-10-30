import 'package:flutter/material.dart';

class ContentWidth extends StatelessWidget {
  static const double readingWidth = 720;

  final Widget child;

  const ContentWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: readingWidth),
        child: child,
      ),
    );
  }
}

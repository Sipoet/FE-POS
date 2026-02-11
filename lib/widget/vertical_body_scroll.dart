import 'package:flutter/material.dart';

class VerticalBodyScroll extends StatelessWidget {
  final Widget child;
  final scrollController = ScrollController();
  VerticalBodyScroll({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 8,
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 10, 25, 10),
          child: child,
        ),
      ),
    );
  }
}

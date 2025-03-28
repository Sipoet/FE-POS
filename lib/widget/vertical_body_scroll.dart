import 'package:flutter/material.dart';

class VerticalBodyScroll extends StatelessWidget {
  final Widget child;
  final scrollController = ScrollController();
  VerticalBodyScroll({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      thickness: 10,
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 10, 25, 5),
          child: child,
        ),
      ),
    );
  }
}

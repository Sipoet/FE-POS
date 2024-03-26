import 'package:flutter/material.dart';

Widget defaultPage() {
  return const Placeholder();
}

class Menu {
  final IconData icon;
  bool isClosed;
  final String label;
  final String key;
  final List<Menu> children;
  final Widget Function() pageFunct;
  final bool isDisabled;
  Menu(
      {required this.icon,
      this.isClosed = true,
      required this.label,
      required this.key,
      this.isDisabled = false,
      this.children = const <Menu>[],
      this.pageFunct = defaultPage});

  Widget get page => pageFunct();
  bool isNotAuthorize() {
    return (children.isEmpty && isDisabled) ||
        (children.isNotEmpty &&
            children.every((menu) => menu.isNotAuthorize()));
  }
}

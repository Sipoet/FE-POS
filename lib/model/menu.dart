import 'package:flutter/material.dart';

class Menu {
  final IconData icon;
  bool isClosed;
  final String label;
  final String key;
  final List<Menu> children;
  final Widget page;
  final bool isDisabled;
  Menu(
      {required this.icon,
      this.isClosed = true,
      required this.label,
      required this.key,
      this.isDisabled = false,
      this.children = const <Menu>[],
      this.page = const Placeholder()});

  bool isNotAuthorize() {
    return (children.isEmpty && isDisabled) ||
        (children.isNotEmpty &&
            children.every((menu) => menu.isNotAuthorize()));
  }
}

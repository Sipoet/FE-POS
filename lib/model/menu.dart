import 'package:flutter/material.dart';

class Menu {
  final IconData icon;
  bool isClosed;
  final String label;
  final String key;
  final List<Menu> children;
  final Widget page;
  Menu(
      {required this.icon,
      this.isClosed = true,
      required this.label,
      required this.key,
      this.children = const <Menu>[],
      this.page = const Placeholder()});
}

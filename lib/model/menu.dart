import 'package:flutter/material.dart';

class Menu {
  IconData icon;
  bool isClosed;
  String label;
  String key;
  List<Menu> children;
  Widget Function() page;
  Menu(
      {required this.icon,
      this.isClosed = true,
      required this.label,
      required this.key,
      this.children = const <Menu>[],
      required this.page});
}

import 'package:flutter/material.dart';

class Menu {
  IconData icon;
  bool isClosed;
  String label;
  String key;
  List<Menu> children;
  Widget page;
  Menu(
      {required this.icon,
      this.isClosed = true,
      required this.label,
      required this.key,
      this.children = const <Menu>[],
      this.page = const Placeholder()});
}

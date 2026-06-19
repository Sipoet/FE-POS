import 'package:flutter/material.dart';

Widget defaultPage() {
  return const Placeholder();
}

class Menu {
  final IconData icon;
  bool isClosed;
  final String label;
  final String key;
  final String? _tabTitle;
  final List<Menu> children;
  final Widget Function() pageFunct;
  final bool isDisabled;
  Menu({
    required this.icon,
    this.isClosed = true,
    required this.label,
    required this.key,
    String? tabTitle,
    this.isDisabled = false,
    List<Menu>? children,
    this.pageFunct = defaultPage,
  }) : _tabTitle = tabTitle,
       children = children ?? [];
  String get tabTitle => _tabTitle ?? label;
  Widget get page => pageFunct();
  bool isNotAuthorize() {
    return (children.isEmpty && isDisabled) ||
        (children.isNotEmpty &&
            children.every((menu) => menu.isNotAuthorize()));
  }
}

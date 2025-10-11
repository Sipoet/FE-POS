import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
export 'package:flutter_simple_treeview/flutter_simple_treeview.dart';

class CustomTreeView extends StatelessWidget {
  final List<CustomTreeNode> nodes;
  final TreeController? treeController;
  final double indent;
  const CustomTreeView({
    super.key,
    this.treeController,
    this.indent = 20,
    this.nodes = const [],
  });

  @override
  Widget build(BuildContext context) {
    return TreeView(
        nodes: nodes.where((e) => e.isDisplay).toList(),
        treeController: treeController,
        indent: indent);
  }
}

class CustomTreeNode<T> extends TreeNode {
  bool isDisplay;
  T? object;
  List<CustomTreeNode<T>>? _rawChildren;

  @override
  List<CustomTreeNode<T>>? get children =>
      _rawChildren?.where((e) => e.isDisplay).toList();

  set children(List<CustomTreeNode<T>>? value) {
    _rawChildren = value;
  }

  void displayAll() {
    isDisplay = true;
    _rawChildren?.forEach((element) {
      element.displayAll();
    });
  }

  List<CustomTreeNode<T>>? get rawChildren => _rawChildren;

  CustomTreeNode(
      {List<CustomTreeNode<T>>? children,
      super.key,
      super.content,
      this.object,
      this.isDisplay = true})
      : _rawChildren = children;
}

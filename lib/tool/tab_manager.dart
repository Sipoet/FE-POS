import 'package:flutter/material.dart';

class TabManager extends ChangeNotifier {
  List<String> tabs = List<String>.filled(99, '', growable: true);
  List<Widget> tabViews =
      List<Widget>.filled(99, const SizedBox(), growable: true);
  late TabController controller;

  int _activeIndex = 0;
  TabManager(TickerProvider obj) {
    controller = TabController(
      vsync: obj,
      length: 99,
      initialIndex: _activeIndex,
    );
  }

  void addTab(String header, Widget tabview) {
    int index = tabs.indexOf(header);
    if (index == -1) {
      tabViews[_activeIndex] = tabview;
      tabs[_activeIndex] = header;
      _activeIndex += 1;
      notifyListeners();
      goTo(_activeIndex - 1);
    } else {
      goTo(index);
    }
  }

  void goTo(int index) {
    controller.animateTo(index);
    notifyListeners();
  }

  void removeTab(header) {
    tabs.remove(header);
    tabs.add('');
    _activeIndex -= 1;
    controller.animateTo(0);
    notifyListeners();
  }
}

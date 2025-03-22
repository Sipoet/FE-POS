import 'package:flutter/material.dart';
import 'package:pluto_layout/pluto_layout.dart';
import 'package:tabbed_view/tabbed_view.dart';

class TabManager extends ChangeNotifier {
  int selectedIndex = 0;
  TabbedViewController controller;
  List<String> get tabs => controller.tabs
      .map<String>((tabItemDetail) => tabItemDetail.text)
      .toList();
  List<Widget?> get tabViews => controller.tabs
      .map<Widget?>((tabItemDetail) => tabItemDetail.content)
      .toList();
  Widget? _safeAreaContent;
  Widget? get safeAreaContent => _safeAreaContent;

  void setSafeAreaContent(String title, Widget content) {
    _safeAreaContent = SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                    onPressed: () => removeRightContent(),
                    icon: Icon(Icons.close))
              ],
            ),
            content,
          ],
        ),
      ),
    );
    notifyListeners();
  }

  void removeRightContent() {
    PlutoLayoutActions.hideAllTabView();
    debugPrint('click close');
    _safeAreaContent = null;
    notifyListeners();
  }

  int emptyIndex = 0;
  TabManager({tabItemDetails = const []})
      : controller = TabbedViewController(tabItemDetails);

  void addTab(String header, Widget tabView, {bool canRemove = true}) async {
    int index = tabs.indexOf(header);
    if (index == -1) {
      controller.addTab(TabData(
          text: header,
          content: tabView,
          closable: canRemove,
          keepAlive: true));

      index = tabs.length - 1;
    }
    goTo(index);
  }

  bool isActive(TabData tabData) {
    return selectedIndex == controller.tabs.indexOf(tabData);
  }

  void goTo(int index) {
    controller.selectedIndex = index;
  }

  void selectById(String id) {
    int index = tabs.indexOf(id);
    goTo(index);
  }

  void changeTabHeader(Widget tabView, String title) {
    int index = tabViews.indexOf(tabView);
    if (index >= 0) {
      final tabItemDetail = controller.getTabByIndex(index);
      tabItemDetail.text = title;
      notifyListeners();
    }
  }
}

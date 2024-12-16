import 'package:flutter/material.dart';
import 'package:pluto_layout/pluto_layout.dart';

class TabManager extends ChangeNotifier {
  List<TabItemDetail> tabItemDetails = [];
  int selectedIndex = 0;
  PlutoLayoutEventStreamController? plutoController;
  List<String> get tabs => tabItemDetails
      .map<String>((tabItemDetail) => tabItemDetail.title)
      .toList();
  List<Widget> get tabViews => tabItemDetails
      .map<Widget>((tabItemDetail) => tabItemDetail.tabView)
      .toList();

  int emptyIndex = 0;
  TabManager();

  void addTab(String header, Widget tabView, {bool canRemove = true}) async {
    int index = tabs.indexOf(header);
    if (index == -1) {
      tabItemDetails.add(
          TabItemDetail(title: header, tabView: tabView, canRemove: canRemove));
      index = tabs.length - 1;
      plutoController?.add(
        PlutoInsertTabItemEvent(
          layoutId: PlutoLayoutId.body,
          itemResolver: ({required List<PlutoLayoutTabItem> items}) {
            return PlutoInsertTabItemResult(
                item: PlutoLayoutTabItem(
                    id: header,
                    title: header,
                    enabled: true,
                    tabViewWidget: tabView,
                    showRemoveButton: canRemove),
                index: index);
          },
        ),
      );
    }
    goTo(index);
  }

  bool isActive(TabItemDetail tabItemDetail) {
    return selectedIndex == tabItemDetails.indexOf(tabItemDetail);
  }

  void goTo(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  void selectById(String id) {
    int index = tabs.indexOf(id);
    goTo(index);
  }

  void changeTabHeader(Widget tabView, String title) {
    int index = tabViews.indexOf(tabView);
    var tabItemDetail = tabItemDetails[index];
    if (index >= 0) {
      tabItemDetail.title = title;
      notifyListeners();
    }
  }

  void removeTab(header) {
    int index = tabs.indexOf(header);
    tabItemDetails.removeAt(index);
    if (selectedIndex == tabItemDetails.length) {
      selectedIndex -= 1;
    }
    notifyListeners();
  }
}

class TabItemDetail {
  String title;
  Widget tabView;
  bool canRemove;
  TabItemDetail(
      {required this.title, required this.tabView, this.canRemove = false});
}

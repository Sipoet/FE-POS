import 'package:flutter/material.dart';
import 'package:pluto_layout/pluto_layout.dart';

class TabManager extends ChangeNotifier {
  List<TabItemDetail> tabItemDetails = [];
  int selectedIndex = 0;
  late TabController controller;
  PlutoLayoutEventStreamController? plutoController;
  List<String> get tabs => tabItemDetails
      .map<String>((tabItemDetail) => tabItemDetail.title)
      .toList();
  List<Widget> get tabViews => tabItemDetails
      .map<Widget>((tabItemDetail) => tabItemDetail.tabView)
      .toList();

  int emptyIndex = 0;
  TabManager(TickerProvider obj) {
    controller = TabController(
      vsync: obj,
      length: 10,
      initialIndex: emptyIndex,
    );
  }

  void addTab(String header, Widget tabView, {bool canRemove = true}) async {
    // int index = tabs.indexOf(header);
    // if (index == -1) {
    //   tabViews[emptyIndex] = tabView;
    //   tabs[emptyIndex] = header;
    //   emptyIndex += 1;
    //   notifyListeners();
    //   goTo(emptyIndex - 1);
    // } else {
    //   goTo(index);
    // }
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
    // controller.animateTo(index);
    selectedIndex = index;

    // for (final (index, plutoTab) in plutoTabs.indexed) {
    //   plutoTabs[index] = PlutoLayoutTabItem(
    //       showRemoveButton: plutoTab.showRemoveButton,
    //       enabled: index == selectedIndex,
    //       id: plutoTab.id,
    //       title: plutoTab.title,
    //       tabViewWidget: plutoTab.tabViewWidget);
    // }
    notifyListeners();
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
    tabs.remove(header);
    tabs.add('');
    tabViews.removeAt(index);
    tabViews.add(const SizedBox());
    emptyIndex -= 1;
    if (controller.index == index) {
      controller.animateTo(index < 1 ? 0 : index - 1);
    } else {
      controller.animateTo(controller.previousIndex);
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

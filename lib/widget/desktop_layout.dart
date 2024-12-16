import 'package:flutter/material.dart';
import 'package:fe_pos/model/menu.dart';
import 'package:pluto_layout/pluto_layout.dart';
import 'package:pluto_menu_bar/pluto_menu_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:fe_pos/tool/tab_manager.dart';

class DesktopLayout extends StatefulWidget {
  const DesktopLayout(
      {super.key,
      required this.menuTree,
      required this.logout,
      required this.version,
      required this.host,
      required this.userName});

  final List<Menu> menuTree;
  final Function logout;
  final String version;
  final String userName;
  final String host;

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout>
    with TickerProviderStateMixin {
  final List<String> disableClosedTabs = ['Home'];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tabManager = context.watch<TabManager>();

    return Scaffold(
      appBar: AppBar(
        title: Tooltip(
          message:
              'SERVER: ${widget.host} | USER: ${widget.userName} | VERSION: ${widget.version} | Allegra POS',
          child: Text(
            'SERVER: ${widget.host} | USER: ${widget.userName} | VERSION: ${widget.version} | Allegra POS',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () {
              widget.logout();
            },
          )
        ],
      ),
      body: PlutoLayout(
        top: PlutoLayoutContainer(
          child: TopMenuBar(
            menuTree: widget.menuTree,
          ),
        ),
        body: PlutoLayoutContainer(
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: PlutoLayoutTabsOrChild(
              draggable: true,
              items: tabManager.tabItemDetails
                  .map<PlutoLayoutTabItem>((tabItemDetail) =>
                      PlutoLayoutTabItem(
                          id: tabItemDetail.title,
                          title: tabItemDetail.title,
                          enabled: tabManager.isActive(tabItemDetail),
                          showRemoveButton: tabItemDetail.canRemove,
                          tabViewWidget: tabItemDetail.tabView))
                  .toList(),
            )),
      ),
    );
  }
}

class TopMenuBar extends StatefulWidget {
  final List<Menu> menuTree;
  const TopMenuBar({super.key, required this.menuTree});

  @override
  State<TopMenuBar> createState() => _TopMenuBarState();
}

class _TopMenuBarState extends State<TopMenuBar> {
  late final TabManager tabManager;

  @override
  void initState() {
    final eventStreamController = PlutoLayout.getEventStreamController(context);
    tabManager = context.read<TabManager>();
    eventStreamController?.listen((PlutoLayoutEvent event) {
      if (event is PlutoRemoveTabItemEvent) {
        tabManager.removeTab(event.itemId);
      } else if (event is PlutoInsertTabItemEvent) {
      } else if (event is PlutoToggleTabViewEvent) {
        tabManager.selectById(event.itemId as String);
      }
    });
    tabManager.plutoController = eventStreamController;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.fuchsia
    ].contains(defaultTargetPlatform);
    return PlutoMenuBar(
        showBackButton: false,
        mode: isMobile ? PlutoMenuBarMode.tap : PlutoMenuBarMode.hover,
        menus: decorateMenus(widget.menuTree));
  }

  List<PlutoMenuItem> decorateMenus(List<Menu> fromMenus) {
    List<PlutoMenuItem> results = [];
    for (final menu in fromMenus) {
      if (menu.isNotAuthorize()) {
        continue;
      } else if (menu.children.isEmpty) {
        results.add(PlutoMenuItem(
          icon: menu.icon,
          onTap: () {
            setState(() {
              tabManager.addTab(menu.label, menu.page);
            });
          },
          title: menu.label,
        ));
      } else {
        results.add(PlutoMenuItem(
          icon: menu.icon,
          children: decorateMenus(menu.children),
          title: menu.label,
        ));
      }
    }
    return results;
  }
}

import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/menu.dart';
import 'package:pluto_layout/pluto_layout.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/tab_manager.dart';

class MobileLayout extends StatefulWidget {
  const MobileLayout(
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
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout>
    with TickerProviderStateMixin {
  final List<String> disableClosedTabs = ['Home'];

  @override
  Widget build(BuildContext context) {
    print('build');
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
      ),
      drawer: LeftMenubar(
        menuTree: widget.menuTree,
      ),
      body: PlutoLayout(
          body: PlutoLayoutContainer(
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: const MobileTab())),
    );
  }
}

class MobileTab extends StatefulWidget {
  const MobileTab({super.key});

  @override
  State<MobileTab> createState() => _MobileTabState();
}

class _MobileTabState extends State<MobileTab> {
  @override
  void initState() {
    final eventStreamController = PlutoLayout.getEventStreamController(context);
    final tabManager = context.read<TabManager>();
    tabManager.plutoController = eventStreamController;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var tabManager = context.watch<TabManager>();
    return PlutoLayoutTabsOrChild(
      draggable: true,
      items: tabManager.tabItemDetails
          .map<PlutoLayoutTabItem>((tabItemDetail) => PlutoLayoutTabItem(
              id: tabItemDetail.title,
              title: tabItemDetail.title,
              enabled: tabManager.isActive(tabItemDetail),
              showRemoveButton: tabItemDetail.canRemove,
              tabViewWidget: tabItemDetail.tabView))
          .toList(),
    );
  }
}

class LeftMenubar extends StatefulWidget {
  final List<Menu> menuTree;
  const LeftMenubar({super.key, required this.menuTree});

  @override
  State<LeftMenubar> createState() => _LeftMenubarState();
}

class _LeftMenubarState extends State<LeftMenubar>
    with SessionState, DefaultResponse {
  Map<String, bool> iconStatus = {};
  late final TabManager tabManager;
  @override
  void initState() {
    tabManager = context.read<TabManager>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final menuWidgets = listMenuNested(widget.menuTree);
    final server = context.read<Server>();
    menuWidgets.add(ListTile(
      leading: const Icon(Icons.power_settings_new),
      onTap: () {
        logout(server);
      },
      title: const Text('Log Out'),
    ));
    return Drawer(
      child: ListView(
        children: menuWidgets,
      ),
    );
  }

  List<Widget> listMenuNested(List<Menu> menus) {
    List<Widget> container = [];
    for (Menu menu in menus) {
      if (menu.isNotAuthorize()) {
        continue;
      }
      iconStatus[menu.key] = menu.isClosed;
      container.add(decorateMenu(menu));
      if (menu.children.isNotEmpty) {
        container.add(Visibility(
          visible: iconStatus[menu.key] == false,
          child: ListView(
            padding: const EdgeInsets.only(left: 10),
            physics: const ClampingScrollPhysics(),
            shrinkWrap: true,
            children: listMenuNested(menu.children),
          ),
        ));
      }
    }
    return container;
  }

  Widget decorateMenu(Menu menu) {
    if (menu.children.isEmpty) {
      return ListTile(
        key: ValueKey(menu.key),
        leading: Icon(menu.icon),
        onTap: () {
          Navigator.pop(context);
          setState(() {
            tabManager.addTab(menu.label, menu.page);
          });
        },
        title: Text(menu.label),
      );
    } else {
      return ListTile(
        key: ValueKey(menu.key),
        leading: Icon(menu.icon),
        title: Text(menu.label),
        onTap: () {
          setState(() {
            menu.isClosed = !menu.isClosed;
            iconStatus[menu.key] = menu.isClosed;
          });
        },
        trailing: Icon(iconStatus[menu.key] == true
            ? Icons.arrow_drop_down
            : Icons.arrow_drop_up),
      );
    }
  }
}

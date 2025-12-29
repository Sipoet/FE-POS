import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/model/user.dart';
import 'package:fe_pos/page/form_page.dart';
import 'package:fe_pos/tool/app_updater.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/menu.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:tabbed_view/tabbed_view.dart';

class MobileLayout extends StatefulWidget {
  const MobileLayout(
      {super.key,
      required this.menuTree,
      required this.host,
      required this.userName});

  final List<Menu> menuTree;
  final String userName;
  final String host;
  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout>
    with
        TickerProviderStateMixin,
        SessionState,
        PlatformChecker,
        DefaultResponse {
  final List<String> disableClosedTabs = ['Home'];

  @override
  Widget build(BuildContext context) {
    final message =
        'SERVER: ${widget.host} | USER: ${widget.userName} | Allegra POS';
    return Scaffold(
      appBar: AppBar(
        toolbarHeight:
            MediaQuery.of(context).orientation == Orientation.portrait
                ? null
                : 30,
        title: Tooltip(
          message: message,
          child: Text(
            message,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      drawer: LeftMenubar(
        menuTree: widget.menuTree,
      ),
      body: const MobileTab(),
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
  Widget build(BuildContext context) {
    var tabManager = context.watch<TabManager>();
    return TabbedViewTheme(
      data: TabbedViewThemeData.mobile(colorSet: Colors.grey, fontSize: 16),
      child: TabbedView(
          onTabSelection: (tabIndex) =>
              tabManager.selectedIndex = tabIndex ?? -1,
          onTabClose: (tabIndex, tabData) {
            tabManager.goTo(tabIndex - 1);
          },
          controller: tabManager.controller),
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
    with SessionState, DefaultResponse, AppUpdater, PlatformChecker {
  Map<String, bool> iconStatus = {};
  late final TabManager tabManager;
  String version = '';

  @override
  void initState() {
    tabManager = context.read<TabManager>();
    appVersion().then((appVersion) => setState(() {
          version = appVersion;
        }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final menuWidgets = listMenuNested(widget.menuTree);
    final server = context.read<Server>();
    if (!isWeb()) {
      menuWidgets.add(ListTile(
        leading: const Icon(Icons.update),
        onTap: () {
          checkUpdate(server, isManual: true);
        },
        title: const Text('Check Update App'),
      ));
      menuWidgets.add(ListTile(
        leading: const Icon(Icons.document_scanner),
        onTap: () {
          openAboutDialog(version);
        },
        title: const Text('About'),
      ));
    }
    menuWidgets.add(ListTile(
      leading: const Icon(Icons.person_2),
      onTap: () {
        final server = context.read<Server>();
        var user = User(username: server.userName);
        tabManager.addTab('Profilku', UserFormPage(user: user));
      },
      title: const Text('Profilku'),
    ));
    menuWidgets.add(ListTile(
      leading: const Icon(Icons.logout),
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
            tabManager.addTab(menu.tabTitle, menu.page);
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

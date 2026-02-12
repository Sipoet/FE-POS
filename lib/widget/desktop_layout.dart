import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/model/user.dart';
import 'package:fe_pos/page/form_page.dart';
import 'package:fe_pos/tool/app_updater.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/menu.dart';
import 'package:pluto_menu_bar/pluto_menu_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:tabbed_view/tabbed_view.dart';

class DesktopLayout extends StatefulWidget {
  const DesktopLayout({
    super.key,
    required this.menuTree,
    required this.host,
    required this.userName,
  });

  final List<Menu> menuTree;
  final String userName;
  final String host;

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout>
    with
        TickerProviderStateMixin,
        SessionState,
        PlatformChecker,
        AppUpdater,
        DefaultResponse {
  final List<String> disableClosedTabs = ['Home'];
  String version = '';
  @override
  void initState() {
    appVersion().then(
      (appVersion) => setState(() {
        version = appVersion;
      }),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tabManager = context.watch<TabManager>();
    final server = context.read<Server>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SERVER: ${widget.host} | USER: ${widget.userName} | Allegra POS',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              List<PopupMenuEntry> result = [];
              if (!isWeb()) {
                result.add(
                  PopupMenuItem(
                    onTap: () => openAboutDialog(version),
                    child: Text('About'),
                  ),
                );
                result.add(
                  PopupMenuItem(
                    onTap: () => checkUpdate(server, isManual: true),
                    child: Text('Cek Update App'),
                  ),
                );
              }
              result.add(
                PopupMenuItem(
                  onTap: () {
                    final server = context.read<Server>();
                    var user = User(username: server.userName);
                    tabManager.addTab(
                      'Profilku',
                      UserFormPage(user: user, fromProfile: true),
                    );
                  },
                  child: Row(
                    children: [
                      Text('Profile'),
                      SizedBox(width: 10),
                      Icon(Icons.person_2),
                    ],
                  ),
                ),
              );
              result.add(
                PopupMenuItem(
                  onTap: () {
                    final server = context.read<Server>();
                    logout(server);
                  },
                  child: Row(
                    children: [
                      Text('Logout'),
                      SizedBox(width: 10),
                      Icon(Icons.logout),
                    ],
                  ),
                ),
              );
              return result;
            },
            icon: Icon(Icons.menu),
          ),
        ],
      ),
      body: Column(
        spacing: 10,
        children: [
          TopMenuBar(menuTree: widget.menuTree),
          Expanded(
            child: ResizableContainer(
              direction: Axis.horizontal,
              divider: ResizableDivider(
                thickness: 5,
                padding: 5,
                color: Colors.blueGrey.shade300,
              ),
              children: [
                ResizableChild(minSize: 500, child: tabViewWidget(tabManager)),
                if (tabManager.safeAreaContent != null)
                  ResizableChild(
                    minSize: 350,
                    maxSize: 800,
                    child: tabManager.safeAreaContent!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget tabViewWidget(TabManager tabManager) => Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: TabbedViewTheme(
          data:
              TabbedViewThemeData.classic(colorSet: Colors.grey, fontSize: 16),
          child: TabbedView(
            onTabSelection: (tabIndex) =>
                tabManager.selectedIndex = tabIndex ?? -1,
            onTabClose: (tabIndex, tabData) {
              tabManager.goTo(tabIndex - 1);
            },
            controller: tabManager.controller,
          ),
        ),
      );
}

class TopMenuBar extends StatefulWidget {
  final List<Menu> menuTree;
  const TopMenuBar({super.key, required this.menuTree});

  @override
  State<TopMenuBar> createState() => _TopMenuBarState();
}

class _TopMenuBarState extends State<TopMenuBar> with PlatformChecker {
  late final TabManager tabManager;

  @override
  void initState() {
    tabManager = context.read<TabManager>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PlutoMenuBar(
        height: 35,
        showBackButton: false,
        mode: isMobile() ? PlutoMenuBarMode.tap : PlutoMenuBarMode.hover,
        menus: decorateMenus(widget.menuTree));
  }

  List<PlutoMenuItem> decorateMenus(List<Menu> fromMenus) {
    List<PlutoMenuItem> results = [];
    for (final menu in fromMenus) {
      if (menu.isNotAuthorize()) {
        continue;
      } else if (menu.children.isEmpty) {
        results.add(
          PlutoMenuItem(
            icon: menu.icon,
            onTap: () {
              setState(() {
                tabManager.addTab(menu.tabTitle, menu.page);
              });
            },
            title: menu.label,
          ),
        );
      } else {
        results.add(
          PlutoMenuItem(
            icon: menu.icon,
            children: decorateMenus(menu.children),
            title: menu.label,
          ),
        );
      }
    }
    return results;
  }
}

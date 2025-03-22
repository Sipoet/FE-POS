import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/menu.dart';
import 'package:pluto_layout/pluto_layout.dart';
import 'package:pluto_menu_bar/pluto_menu_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:tabbed_view/tabbed_view.dart';

class DesktopLayout extends StatefulWidget {
  const DesktopLayout(
      {super.key,
      required this.menuTree,
      required this.host,
      required this.userName});

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
        DefaultResponse {
  final List<String> disableClosedTabs = ['Home'];
  String version = '';
  @override
  void initState() {
    appVersion().then((appVersion) => setState(() {
          version = appVersion;
        }));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tabManager = context.watch<TabManager>();
    final message =
        'SERVER: ${widget.host} | USER: ${widget.userName} | VERSION: $version | Allegra POS';
    return Scaffold(
        appBar: AppBar(
          title: Tooltip(
            message: message,
            child: Text(
              message,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              onPressed: () {
                final server = context.read<Server>();
                logout(server);
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
            child: ResizableContainer(
              direction: Axis.horizontal,
              divider: ResizableDivider(
                  thickness: 5, padding: 5, color: Colors.blueGrey.shade300),
              children: [
                ResizableChild(minSize: 500, child: tabViewWidget(tabManager)),
                if (tabManager.safeAreaContent != null)
                  ResizableChild(
                      minSize: 350,
                      maxSize: 800,
                      child: tabManager.safeAreaContent!),
              ],
            ),
          ),
        ));
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
              controller: tabManager.controller),
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

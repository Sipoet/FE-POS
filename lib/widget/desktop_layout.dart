import 'package:flutter/material.dart';
import 'package:fe_pos/model/menu.dart';
import 'package:provider/provider.dart';
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
  Widget build(BuildContext context) {
    var tabManager = context.read<TabManager>();
    var menus = decorateMenus(widget.menuTree);
    menus.add(
      MenuItemButton(
        leadingIcon: const Icon(Icons.power_settings_new),
        onPressed: () {
          widget.logout();
        },
        child: const Text('Log Out'),
      ),
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TabManager>(create: (_) => tabManager),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Tooltip(
            message:
                'SERVER: ${widget.host} | USER: ${widget.userName} | VERSION: ${widget.version} | Allegra POS',
            child: Text(
              'SERVER: ${widget.host} | USER: ${widget.userName} | VERSION: ${widget.version} | Allegra POS',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          actions: [MenuBar(style: const MenuStyle(), children: menus)],
          bottom: TabBar(
            isScrollable: true,
            controller: tabManager.controller,
            onTap: (index) {
              var controller = tabManager.controller;
              if (controller.indexIsChanging &&
                  tabManager.emptyIndex <= index) {
                controller.index = controller.previousIndex;
              } else {
                return;
              }
            },
            tabs: tabManager.tabs
                .map<Widget>((header) => SizedBox(
                      height: 40,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Tooltip(
                              message: header,
                              child: Text(
                                header,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          if (header.isNotEmpty &&
                              !disableClosedTabs.contains(header))
                            IconButton(
                                onPressed: () => setState(() {
                                      tabManager.removeTab(header);
                                    }),
                                icon: const Icon(Icons.close))
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        body: bodyWidget(),
      ),
    );
  }

  Widget bodyWidget() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: tabWidget(),
    );
  }

  Widget tabWidget() {
    var tabManager = context.read<TabManager>();
    return TabBarView(
      physics: const NeverScrollableScrollPhysics(),
      controller: tabManager.controller,
      children: tabManager.tabViews,
    );
    // return TabBar(tabs: tabs);
  }

  List<Widget> decorateMenus(List<Menu> fromMenus,
      {MenuController? parentMenuController}) {
    var tabManager = context.watch<TabManager>();
    return fromMenus.map<Widget>((menu) {
      if (menu.isNotAuthorize()) {
        return const SizedBox();
      } else if (menu.children.isEmpty) {
        return MenuItemButton(
          leadingIcon: Icon(menu.icon),
          onPressed: () {
            parentMenuController?.close;
            setState(() {
              tabManager.addTab(menu.label, menu.page);
            });
          },
          child: Text(menu.label),
        );
      } else {
        final menuController = MenuController();
        return SubmenuButton(
          controller: menuController,
          leadingIcon: Icon(menu.icon),
          menuChildren: decorateMenus(menu.children,
              parentMenuController: menuController),
          child: Text(menu.label),
        );
      }
    }).toList();
  }
}

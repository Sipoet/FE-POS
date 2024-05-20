import 'package:fe_pos/model/server.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/menu.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/tab_manager.dart';

class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key, required this.menuTree, required this.logout});

  final List<Menu> menuTree;
  final Function logout;

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout>
    with TickerProviderStateMixin {
  List<Widget> _menus = [];
  final List<String> disableClosedTabs = ['Home'];

  @override
  void initState() {
    _menus = widget.menuTree.toList().map<Widget>((menu) {
      return decorateMenu(menu);
    }).toList();
    _menus.add(
      ListTile(
        leading: const Icon(Icons.power_settings_new),
        onTap: () {
          widget.logout();
        },
        title: const Text('Log Out'),
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var tabManager = context.read<TabManager>();
    final server = context.read<Server>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Allegra POS. SERVER: ${server.host}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          isScrollable: true,
          controller: tabManager.controller,
          onTap: (index) {
            var controller = tabManager.controller;
            if (controller.indexIsChanging && tabManager.emptyIndex <= index) {
              controller.index = controller.previousIndex;
            } else {
              return;
            }
          },
          tabs: tabManager.tabs
              .map<Widget>((header) => Row(
                    children: [
                      Text(
                        header,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (header.isNotEmpty &&
                          !disableClosedTabs.contains(header))
                        IconButton(
                            onPressed: () => setState(() {
                                  tabManager.removeTab(header);
                                }),
                            icon: const Icon(Icons.close))
                    ],
                  ))
              .toList(),
        ),
      ),
      drawer: Drawer(
          child: ListView.builder(
        itemBuilder: (context, index) => _menus[index],
        itemCount: _menus.length,
      )),
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: tabManager.controller,
        children: tabManager.tabViews,
      ),
    );
  }

  Widget decorateMenu(Menu menu) {
    if (menu.isNotAuthorize()) {
      return const SizedBox();
    } else if (menu.children.isEmpty) {
      return ListTile(
        key: ValueKey(menu.key),
        leading: Icon(menu.icon),
        onTap: () {
          setState(() {
            Navigator.pop(context);
            var tabManager = context.read<TabManager>();
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
            int index = _menus.indexWhere((tile) {
              return tile.key == ValueKey(menu.key);
            });
            if (menu.isClosed) {
              int childrenCount = menu.children.length;
              _menus.removeRange(index + 1, index + childrenCount + 1);
            } else {
              _menus.insertAll(index + 1,
                  menu.children.map<Widget>((childMenu) {
                return decorateMenu(childMenu);
              }));
            }
          });
        },
        trailing:
            Icon(menu.isClosed ? Icons.arrow_drop_down : Icons.arrow_drop_up),
      );
    }
  }
}

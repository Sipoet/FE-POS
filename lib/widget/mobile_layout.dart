import 'package:flutter/material.dart';
import 'package:fe_pos/model/menu.dart';
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
  late final List<Menu> _menus;

  @override
  void initState() {
    _menus = List.from(widget.menuTree);
    super.initState();
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
        if (menu.key == 'report') {
          debugPrint('decorate ${menu.key} ${iconStatus[menu.key]}');
        }
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

  @override
  Widget build(BuildContext context) {
    var tabManager = context.read<TabManager>();
    final menuWidgets = listMenuNested(_menus);
    menuWidgets.add(ListTile(
      leading: const Icon(Icons.power_settings_new),
      onTap: () {
        widget.logout();
      },
      title: const Text('Log Out'),
    ));
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: header.isNotEmpty &&
                              !disableClosedTabs.contains(header),
                          child: IconButton(
                              onPressed: () => setState(() {
                                    tabManager.removeTab(header);
                                  }),
                              icon: const Icon(Icons.close)),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: menuWidgets,
        ),
      ),
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: tabManager.controller,
        children: tabManager.tabViews,
      ),
    );
  }

  Map<String, bool> iconStatus = {};

  Widget decorateMenu(Menu menu) {
    if (menu.children.isEmpty) {
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

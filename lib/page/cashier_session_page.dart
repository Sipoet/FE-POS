import 'package:fe_pos/model/cashier_session.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/page/edc_settlement_form_page.dart';
import 'package:fe_pos/page/cashier_session_table_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CashierSessionPage extends StatefulWidget {
  const CashierSessionPage({super.key});

  @override
  State<CashierSessionPage> createState() => _CashierSessionPageState();
}

class _CashierSessionPageState extends State<CashierSessionPage>
    with DefaultResponse, AutomaticKeepAliveClientMixin, LoadingPopup {
  final _menuController = MenuController();
  late final TabManager tabManager;
  late final Server server;
  late final Setting setting;
  CashierSession cashierSession = CashierSession();
  bool _isTodayCashierFetched = false;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    tabManager = context.read<TabManager>();
    server = context.read<Server>();
    setting = context.read<Setting>();
    super.initState();
    Future.delayed(Duration.zero, _fetchCashierSessionToday);
  }

  void _fetchCashierSessionToday() {
    showLoadingPopup();
    server
        .get('cashier_sessions/today')
        .then(
          (response) {
            if (response.statusCode == 200) {
              final json = response.data;
              setState(() {
                cashierSession = CashierSessionClass().fromJson(
                  json['data'],
                  included: json['included'] ?? [],
                );
                _isTodayCashierFetched = true;
              });
            }
          },
          onError: (error) {
            final response = error.response;
            if (response?.statusCode == 404) {
              _createCashierSessionToday();
            } else {
              defaultErrorResponse(error: error);
            }
          },
        )
        .whenComplete(() => hideLoadingPopup());
  }

  void _createCashierSessionToday() {
    showLoadingPopup();
    final bodyParams = {
      'data': {
        'type': 'cashier_session',
        'attributes': cashierSession.toJson(),
      },
    };
    server
        .post('cashier_sessions', body: bodyParams)
        .then((response) {
          if (response.statusCode == 201) {
            final json = response.data;
            setState(() {
              cashierSession = CashierSessionClass().fromJson(
                json['data'],
                included: json['included'] ?? [],
              );
              _isTodayCashierFetched = true;
            });
          }
        }, onError: (error) => defaultErrorResponse(error: error))
        .whenComplete(() => hideLoadingPopup());
  }

  void openTodayEdcSettlement() {
    tabManager.addTab(
      "EDC Settlement hari ini",
      EdcSettlementFormPage(
        key: ObjectKey(cashierSession),
        cashierSession: cashierSession,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const Text("Sesi Kasir Hari Ini"),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 50,
                  child: SubmenuButton(
                    controller: _menuController,
                    menuChildren: [
                      if (_isTodayCashierFetched &&
                          setting.isAuthorize('edcSettlement', 'update'))
                        MenuItemButton(
                          onPressed: () {
                            _menuController.close();
                            openTodayEdcSettlement();
                          },
                          child: const Text('EDC Settlement Hari ini'),
                        ),
                      MenuItemButton(
                        onPressed: () {
                          _menuController.close();
                        },
                        child: const Text('Tambah Kas Keluar'),
                      ),
                    ],
                    child: const Icon(Icons.table_rows_rounded),
                  ),
                ),
              ],
            ),
            Visibility(
              visible: setting.isAuthorize('cashierSession', 'index'),
              child: const CashierSessionTablePage(),
            ),
          ],
        ),
      ),
    );
  }
}

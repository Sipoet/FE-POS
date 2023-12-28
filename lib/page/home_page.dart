import 'package:fe_pos/model/session_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _panels = <Widget>[
    SalesTodayReport(),
    ItemSalesTodayReport(
        key: ValueKey('brand'),
        groupKey: 'brand',
        limit: 5,
        label: 'Merek Terjual Terbanyak'),
    ItemSalesTodayReport(
        key: ValueKey('item_type'),
        groupKey: 'item_type',
        limit: 5,
        label: 'Departemen Terjual Terbanyak'),
    ItemSalesTodayReport(
        key: ValueKey('supplier'),
        groupKey: 'supplier',
        limit: 5,
        label: 'Supplier Terjual Terbanyak'),
  ];

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        addAutomaticKeepAlives: false,
        itemBuilder: (context, index) => Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                border: Border.all(color: colorScheme.outline, width: 2)),
            child: _panels[index]),
        itemCount: _panels.length,
        separatorBuilder: (context, index) => const SizedBox(
          height: 10,
        ),
      ),
    );
  }
}

class SalesTodayReport extends StatefulWidget {
  const SalesTodayReport({super.key});

  @override
  State<SalesTodayReport> createState() => _SalesTodayReportState();
}

class _SalesTodayReportState extends State<SalesTodayReport> {
  double totalSales = 0.0;
  double totalDebit = 0.0;
  double totalCash = 0.0;
  double totalCredit = 0.0;
  double totalQRIS = 0.0;
  double totalOnline = 0.0;
  int totalTransaction = 0;

  @override
  void initState() {
    refreshReport();
    super.initState();
  }

  void refreshReport() {
    var sessionState = context.read<SessionState>();
    sessionState.server.get('sales/today_report').then((response) {
      if (response.statusCode == 200) {
        var data = response.data['data'];
        setState(() {
          totalSales = double.parse(data['sales_total']);
          totalDebit = double.parse(data['debit_total']);
          totalCredit = double.parse(data['credit_total']);
          totalCash = double.parse(data['cash_total']);
          totalOnline = double.parse(data['online_total']);
          totalQRIS = double.parse(data['qris_total']);
          totalTransaction = data['num_of_transaction'];
        });
      }
    },
        onError: (error, stack) => sessionState.server
            .defaultResponse(context: context, error: error));
  }

  String _moneyFormat(double value) {
    var formater = NumberFormat.currency(locale: "en_US", symbol: "Rp");
    return formater.format(value);
  }

  String _dateToday() {
    return DateFormat('EEEEE, d/M/y', 'id_ID').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var labelStyle = TextStyle(color: colorScheme.onPrimaryContainer);
    var valueStyle = TextStyle(
        color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w400);
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Laporan penjualan hari ini',
                style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                  tooltip: 'Refresh Laporan',
                  alignment: Alignment.centerRight,
                  onPressed: () => refreshReport(),
                  color: colorScheme.onPrimaryContainer,
                  icon: const Icon(Icons.refresh_rounded))
            ],
          ),
          Text(
            _dateToday(),
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
          ),
          const Divider(),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(150),
              1: FixedColumnWidth(10)
            },
            children: [
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    'Total Penjualan',
                    style: labelStyle,
                  ),
                ),
                const Text(':'),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    _moneyFormat(totalSales),
                    textAlign: TextAlign.right,
                    style: valueStyle,
                  ),
                )
              ]),
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    'Total Transaksi',
                    style: labelStyle,
                  ),
                ),
                const Text(':'),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    totalTransaction.toString(),
                    textAlign: TextAlign.right,
                    style: valueStyle,
                  ),
                )
              ]),
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    'Total Tunai',
                    style: labelStyle,
                  ),
                ),
                const Text(':'),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    _moneyFormat(totalCash),
                    textAlign: TextAlign.right,
                    style: valueStyle,
                  ),
                )
              ]),
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    'Total Debit',
                    style: labelStyle,
                  ),
                ),
                const Text(':'),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    _moneyFormat(totalDebit),
                    textAlign: TextAlign.right,
                    style: valueStyle,
                  ),
                )
              ]),
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    'Total Kredit',
                    style: labelStyle,
                  ),
                ),
                const Text(':'),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    _moneyFormat(totalCredit),
                    textAlign: TextAlign.right,
                    style: valueStyle,
                  ),
                )
              ]),
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    'Total QRIS',
                    style: labelStyle,
                  ),
                ),
                const Text(':'),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    _moneyFormat(totalQRIS),
                    textAlign: TextAlign.right,
                    style: valueStyle,
                  ),
                )
              ]),
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    'Total Online',
                    style: labelStyle,
                  ),
                ),
                const Text(':'),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    _moneyFormat(totalOnline),
                    textAlign: TextAlign.right,
                    style: valueStyle,
                  ),
                )
              ]),
            ],
          ),
        ]);
  }
}

class ItemSalesTodayReport extends StatefulWidget {
  final String groupKey;
  final int limit;
  final String label;
  const ItemSalesTodayReport({
    super.key,
    required this.label,
    required this.groupKey,
    required this.limit,
  });

  @override
  State<ItemSalesTodayReport> createState() => _ItemSalesTodayReportState();
}

class _ItemSalesTodayReportState extends State<ItemSalesTodayReport> {
  List results = [];

  @override
  void initState() {
    refreshReport();
    super.initState();
  }

  void refreshReport() {
    var sessionState = context.read<SessionState>();
    sessionState.server.get('item_sales/today_report', queryParam: {
      'group_key': widget.groupKey,
      'limit': widget.limit.toString()
    }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          results = response.data['data'];
        });
      }
    },
        onError: (error, stack) => sessionState.server
            .defaultResponse(context: context, error: error));
  }

  String _moneyFormat(double value) {
    var formater = NumberFormat.currency(locale: "en_US", symbol: "Rp");
    return formater.format(value);
  }

  String _humanizeKey(String key) {
    switch (key) {
      case 'brand':
        return 'Merek';
      case 'item_type':
        return 'Jenis / Departemen';
      case 'supplier':
        return 'Supplier';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var style = TextStyle(
        fontWeight: FontWeight.w500, color: colorScheme.onSecondaryContainer);
    int index = 0;
    Size size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    double width = size.width - padding.left - padding.right - 50;
    if (width < 600) {
      width = 600.0;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold),
            ),
            IconButton(
                color: colorScheme.onPrimaryContainer,
                tooltip: 'Refresh Laporan',
                alignment: Alignment.centerRight,
                onPressed: () => refreshReport(),
                icon: const Icon(Icons.refresh_rounded))
          ],
        ),
        if (results.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade400.withOpacity(0.5),
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(35),
                    3: FixedColumnWidth(35),
                  },
                  children: <TableRow>[
                        TableRow(
                            decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer),
                            children: [
                              Text(
                                'NO',
                                style: style,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                _humanizeKey(widget.groupKey),
                                style: style,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Total Terjual',
                                style: style,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'QTY',
                                style: style,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Total Diskon',
                                style: style,
                                textAlign: TextAlign.center,
                              )
                            ]),
                      ] +
                      results
                          .map<TableRow>((row) => TableRow(
                                  decoration: BoxDecoration(
                                      color: index.isEven
                                          ? colorScheme.tertiaryContainer
                                          : colorScheme.secondaryContainer),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        (index += 1).toString(),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            color: index.isOdd
                                                ? colorScheme
                                                    .onTertiaryContainer
                                                : colorScheme
                                                    .onSecondaryContainer),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        row['identifier'],
                                        style: TextStyle(
                                            color: index.isOdd
                                                ? colorScheme
                                                    .onTertiaryContainer
                                                : colorScheme
                                                    .onSecondaryContainer),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        _moneyFormat(
                                          row['sales_total'],
                                        ),
                                        style: TextStyle(
                                            color: index.isOdd
                                                ? colorScheme
                                                    .onTertiaryContainer
                                                : colorScheme
                                                    .onSecondaryContainer),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        row['quantity'].toString(),
                                        style: TextStyle(
                                            color: index.isOdd
                                                ? colorScheme
                                                    .onTertiaryContainer
                                                : colorScheme
                                                    .onSecondaryContainer),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        _moneyFormat(row['discount_total']),
                                        style: TextStyle(
                                            color: index.isOdd
                                                ? colorScheme
                                                    .onTertiaryContainer
                                                : colorScheme
                                                    .onSecondaryContainer),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ]))
                          .toList()),
            ),
          ),
      ],
    );
  }
}

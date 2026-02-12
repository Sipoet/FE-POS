import 'package:collection/collection.dart';
import 'package:fe_pos/page/item_form_page.dart';
import 'package:fe_pos/tool/query_data.dart';
import 'package:fe_pos/model/sale.dart';
import 'package:fe_pos/page/sale_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/transaction_report_controller.dart';
export 'package:fe_pos/tool/transaction_report_controller.dart';
import 'package:fe_pos/tool/platform_checker.dart';

class LastItemSalesTransactionWidget extends StatefulWidget {
  final int limit;

  final TransactionReportController? controller;
  const LastItemSalesTransactionWidget({
    super.key,
    this.limit = 5,
    this.controller,
  });
  @override
  State<LastItemSalesTransactionWidget> createState() =>
      _LastItemSalesTransactionWidgetState();
}

class _LastItemSalesTransactionWidgetState
    extends State<LastItemSalesTransactionWidget>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        DefaultResponse,
        PlatformChecker,
        TextFormatter {
  List<SaleItem> saleItems = [];
  late int limit;
  CancelToken cancelToken = CancelToken();
  late final Setting setting;
  late AnimationController _controller;
  final _scrollController = ScrollController();
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
    end: DateTime.now().copyWith(
      hour: 23,
      minute: 59,
      second: 59,
      millisecond: 999,
    ),
  );
  @override
  void initState() {
    limit = widget.limit;
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addListener(() {
            if (mounted) {
              setState(() {});
            }
          })
          ..addStatusListener((status) {
            if (mounted && status == AnimationStatus.completed) {
              _controller.reset();
              _controller.forward();
            }
          });
    setting = context.read<Setting>();
    _dateRange = widget.controller?.range ?? _dateRange;
    widget.controller?.addListener(setDateAndRefreshReport);

    refreshReport();
    super.initState();
  }

  void setDateAndRefreshReport() {
    setState(() {
      _dateRange = widget.controller?.range ?? _dateRange;
      refreshReport();
    });
  }

  void refreshReport() {
    _controller.reset();
    _controller.forward();
    final server = context.read<Server>();
    SaleItemClass()
        .finds(
          server,
          QueryRequest(
            page: 1,
            limit: limit,
            filters: [
              BetweenFilterData(
                key: 'transaction_date',
                values: [_dateRange.start, _dateRange.end],
              ),
              ComparisonFilterData(key: 'sale_type', value: ['KSR', 'JL']),
            ],
            include: ['item', 'sale'],
            sorts: [SortData(key: 'transaction_date', isAscending: false)],
          ),
        )
        .then((response) {
          if (!mounted) return;

          setState(() {
            saleItems = response.models;
          });
        }, onError: (error, stack) => defaultErrorResponse(error: error))
        .whenComplete(() {
          if (_controller.isAnimating) _controller.reset();
        });
  }

  @override
  void dispose() {
    cancelToken.cancel();
    _controller.dispose();
    widget.controller?.removeListener(setDateAndRefreshReport);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var colorScheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      color: colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.bold,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Penjualan Item Terakhir',
              style: TextStyle(
                fontSize: 18,
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
            IconButton.filled(
              tooltip: 'Refresh Laporan',
              alignment: Alignment.centerRight,
              onPressed: () => refreshReport(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownMenu<int>(
          width: 100,
          textStyle: TextStyle(
            fontSize: 18,
            color: colorScheme.onPrimaryContainer,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            isDense: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.only(left: 10, right: 0),
            border: OutlineInputBorder(),
          ),
          dropdownMenuEntries: [5, 10, 20, 50, 100]
              .map<DropdownMenuEntry<int>>(
                (value) => DropdownMenuEntry<int>(
                  value: value,
                  label: value.toString(),
                ),
              )
              .toList(),
          initialSelection: limit,
          onSelected: (value) {
            limit = value ?? 5;
            refreshReport();
          },
        ),
        const SizedBox(height: 10),
        if (_controller.isAnimating)
          Center(
            child: CircularProgressIndicator(
              value: _controller.value,
              semanticsLabel: 'Dalam proses data',
            ),
          ),
        if (!_controller.isAnimating) const Divider(),
        if (!_controller.isAnimating)
          Scrollbar(
            thumbVisibility: true,
            thickness: 9,
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: .horizontal,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: SizedBox(
                  width: 1200,
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(150),
                      1: FlexColumnWidth(1.5),
                      2: FixedColumnWidth(100),
                      3: FlexColumnWidth(0.8),
                      4: FlexColumnWidth(0.5),
                      5: FlexColumnWidth(0.8),
                    },
                    border: TableBorder.all(
                      color: Colors.grey.shade400.withValues(alpha: 0.5),
                    ),
                    children:
                        [
                          TableRow(
                            key: ValueKey('Header Table Last Item Sale'),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                            ),
                            children: [
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Tanggal', style: labelStyle),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Item', style: labelStyle),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('Jumlah', style: labelStyle),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('Harga', style: labelStyle),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('Diskon', style: labelStyle),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('Subtotal', style: labelStyle),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'No Transaksi',
                                    style: labelStyle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] +
                        saleItems
                            .mapIndexed<TableRow>(
                              (index, saleItem) => TableRow(
                                key: ObjectKey(saleItem),
                                decoration: BoxDecoration(
                                  color: index.isEven
                                      ? colorScheme.tertiaryContainer
                                      : colorScheme.secondaryContainer,
                                ),
                                children: [
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.top,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SelectableText(
                                        dateTimeLocalFormat(
                                          saleItem.transactionDate,
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.top,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: InkWell(
                                        onTap: () =>
                                            _openItemDetail(saleItem.item),
                                        child: Text(
                                          '${saleItem.itemCode} - ${saleItem.itemName}',
                                          style: TextStyle(
                                            fontStyle: .italic,
                                            decoration: .underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.top,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: SelectableText(
                                          numberFormat(saleItem.quantity),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.top,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: SelectableText(
                                          moneyFormat(saleItem.price),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.top,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: SelectableText(
                                          moneyFormat(saleItem.totalDiscount),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.top,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: SelectableText(
                                          moneyFormat(saleItem.subtotal),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.top,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: InkWell(
                                        onTap: saleItem.sale == null
                                            ? null
                                            : () => _openSaleDetail(
                                                saleItem.sale!,
                                              ),
                                        child: Text(
                                          saleItem.saleCode ?? '',
                                          style: TextStyle(
                                            fontStyle: .italic,
                                            decoration: .underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openSaleDetail(Sale sale) {
    final tabManager = context.read<TabManager>();
    if (isDesktop()) {
      tabManager.setSafeAreaContent(
        'Penjualan ${sale.code}',
        SaleFormPage(sale: sale, key: ObjectKey(sale)),
      );
    } else {
      tabManager.addTab(
        'Penjualan ${sale.code}',
        SaleFormPage(sale: sale, key: ObjectKey(sale)),
      );
    }
  }

  void _openItemDetail(Item item) {
    final tabManager = context.read<TabManager>();
    if (isDesktop()) {
      tabManager.setSafeAreaContent(
        'Item ${item.code}',
        ItemFormPage(item: item, key: ObjectKey(item)),
      );
    } else {
      tabManager.addTab(
        'Item ${item.code}',
        ItemFormPage(item: item, key: ObjectKey(item)),
      );
    }
  }
}

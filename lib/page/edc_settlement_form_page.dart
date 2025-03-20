import 'package:fe_pos/model/cashier_session.dart';
import 'package:fe_pos/model/edc_settlement.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/tool/thousand_separator_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class EdcSettlementFormPage extends StatefulWidget {
  final CashierSession cashierSession;
  const EdcSettlementFormPage({super.key, required this.cashierSession});

  @override
  State<EdcSettlementFormPage> createState() => _EdcSettlementFormPageState();
}

class _EdcSettlementFormPageState extends State<EdcSettlementFormPage>
    with
        DefaultResponse,
        LoadingPopup,
        AutomaticKeepAliveClientMixin,
        TextFormatter {
  late final Server server;
  late final Setting setting;
  late Flash flash;
  List<EdcSettlement> edcSettlements = [];
  bool _displaySummary = false;
  final _focusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  final _headerStyle =
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
  @override
  bool get wantKeepAlive => true;

  CashierSession get cashierSession => widget.cashierSession;

  @override
  void initState() {
    flash = Flash();
    server = context.read<Server>();
    setting = context.read<Setting>();
    super.initState();
    _focusNode.requestFocus();
    Future.delayed(Duration.zero, fetchEdcSettlement);
  }

  void fetchEdcSettlement() {
    showLoadingPopup();
    server.get('cashier_sessions/${cashierSession.id}/edc_settlements',
        queryParam: {
          'include': 'payment_type,payment_provider,cashier_session',
          'fields[payment_type]': 'name',
          'fields[payment_provider]': 'name',
          'page[page]': '1',
          'page[limit]': '999999',
        }).then((response) {
      if (response.statusCode == 200) {
        final jsonData = response.data['data'];
        setState(() {
          edcSettlements = jsonData
              .map<EdcSettlement>((json) => EdcSettlement.fromJson(json,
                  included: response.data['included'] ?? []))
              .toList();
        });
      }
    }, onError: (error) => defaultErrorResponse(error: error)).whenComplete(
        () => hideLoadingPopup());
  }

  List<TableCell> _headerTable() {
    List<TableCell> header = [
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Text(
          setting.columnName('edcSettlement', 'payment_provider_id'),
          style: _headerStyle,
        ),
      )),
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(5),
        child: Text(setting.columnName('edcSettlement', 'payment_type_id'),
            style: _headerStyle),
      )),
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(5),
        child: Text(setting.columnName('edcSettlement', 'amount'),
            style: _headerStyle),
      )),
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(5),
        child: Text(setting.columnName('edcSettlement', 'terminal_id'),
            style: _headerStyle),
      )),
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(5),
        child: Text(setting.columnName('edcSettlement', 'merchant_id'),
            style: _headerStyle),
      )),
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(5),
        child: Text('Action', style: _headerStyle),
      )),
    ];
    if (setting.canShow('edcSettlement', 'status')) {
      header.insert(
        header.length - 1,
        TableCell(
            child: Padding(
          padding: const EdgeInsets.all(5),
          child: Text(setting.columnName('edcSettlement', 'status'),
              style: _headerStyle),
        )),
      );
    }
    return header;
  }

  TableRow _rowForm(EdcSettlement edcSettlement) {
    final textController =
        TextEditingController(text: edcSettlement.merchantId.toString());
    List<TableCell> rows = [
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AsyncDropdown<PaymentProvider>(
          allowClear: false,
          textOnSearch: (paymentProvider) => paymentProvider.name,
          selected: edcSettlement.paymentProvider,
          converter: PaymentProvider.fromJson,
          request: (
              {int page = 1,
              int limit = 20,
              String searchText = '',
              required CancelToken cancelToken}) {
            return server.get('payment_providers',
                queryParam: {
                  'page[page]': page.toString(),
                  'page[limit]': limit.toString(),
                  'search_text': searchText,
                  'filter[status][eq]': PaymentProviderStatus.active.toString(),
                },
                cancelToken: cancelToken);
          },
          validator: (value) {
            if (value == null) {
              return 'harus diisi';
            }
            return null;
          },
          onChanged: (paymentProvider) {
            setState(() {
              edcSettlement.paymentProvider =
                  paymentProvider ?? PaymentProvider();
            });
          },
        ),
      )),
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AsyncDropdown<PaymentType>(
            allowClear: false,
            textOnSearch: (paymentType) => paymentType.name,
            selected: edcSettlement.paymentType,
            converter: PaymentType.fromJson,
            onChanged: (paymentType) {
              edcSettlement.paymentType = paymentType ?? PaymentType();
            },
            validator: (value) {
              if (value == null) {
                return 'harus diisi';
              }
              return null;
            },
            path: 'payment_types'),
      )),
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            ThousandSeparatorFormatter(),
          ],
          decoration: const InputDecoration(border: OutlineInputBorder()),
          initialValue: edcSettlement.amount.value.toString(),
          onChanged: (value) {
            edcSettlement.amount =
                Money.tryParse(value.replaceAll(RegExp(r','), '')) ??
                    const Money(0);
          },
        ),
      )),
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AsyncDropdown<PaymentProviderEdc>(
          textOnSearch: (data) => data.terminalId,
          allowClear: false,
          selected: PaymentProviderEdc(
              terminalId: edcSettlement.terminalId,
              merchantId: edcSettlement.merchantId),
          converter: PaymentProviderEdc.fromJson,
          onChanged: (data) {
            setState(() {
              edcSettlement.terminalId = data?.terminalId ?? '';
              edcSettlement.merchantId = data?.merchantId ?? '';
              textController.text = edcSettlement.merchantId;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'harus diisi';
            }
            return null;
          },
          request: (
              {int page = 1,
              int limit = 20,
              String searchText = '',
              required CancelToken cancelToken}) {
            final paymentProviderId =
                edcSettlement.paymentProviderId.toString();
            return server.get('payment_provider_edcs',
                queryParam: {
                  'page[page]': page.toString(),
                  'page[limit]': limit.toString(),
                  'search_text': searchText,
                  'filter[payment_provider_id][eq]': paymentProviderId,
                },
                cancelToken: cancelToken);
          },
        ),
      )),
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          decoration: const InputDecoration(border: OutlineInputBorder()),
          controller: textController,
          readOnly: true,
        ),
      )),
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                iconSize: 35,
                onPressed: () => _removeEdcSettlement(edcSettlement),
                icon: const Icon(Icons.close))
          ],
        ),
      )),
    ];
    if (setting.canShow('edcSettlement', 'status')) {
      rows.insert(
          rows.length - 1,
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: DropdownMenu<EdcSettlementStatus>(
                width: 220,
                initialSelection: edcSettlement.status,
                onSelected: (value) =>
                    edcSettlement.status = value ?? edcSettlement.status,
                dropdownMenuEntries: EdcSettlementStatus.values
                    .map<DropdownMenuEntry<EdcSettlementStatus>>((status) =>
                        DropdownMenuEntry<EdcSettlementStatus>(
                            value: status, label: status.humanize()))
                    .toList(),
              ),
            ),
          ));
    }
    return TableRow(children: rows);
  }

  void _removeEdcSettlement(EdcSettlement edcSettlement) {
    setState(() {
      edcSettlements.remove(edcSettlement);
    });
  }

  void _submitEdcs() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _saveEdc();
    }
  }

  void _saveEdc() {
    showLoadingPopup();
    cashierSession.edcSettlements = edcSettlements;
    final bodyParam = {
      'data': {
        'type': 'cashier_sessions',
        'id': cashierSession.id.toString(),
        'attributes': cashierSession.toJson(),
        'relationships': {
          'edc_settlements': {
            'data': cashierSession.edcSettlements
                .map<Map>((edcSettlement) => {
                      'id': edcSettlement.id,
                      'type': 'edc_settlement',
                      'attributes': edcSettlement.toJson()
                    })
                .toList()
          }
        }
      },
    };
    server
        .put('cashier_sessions/${cashierSession.id.toString()}',
            body: bodyParam)
        .then((response) {
      if (response.statusCode == 200) {
        flash.show(const Text('Berhasil disimpan'), ToastificationType.success);
        fetchEdcSettlement();
      } else {
        var data = response.data;
        flash.showBanner(
            title: data['message'],
            description: (data['errors'] ?? []).join('\n'),
            messageType: ToastificationType.error);
      }
    }, onError: (error) {}).whenComplete(() => hideLoadingPopup());
  }

  List<EdcSummary> edcSummaries = [];
  List<TableRow> _summaryRows() {
    return edcSummaries.map<TableRow>((edcSummary) {
      late Color color;
      if (edcSummary.status == EdcSummaryStatus.same) {
        color = const Color.fromARGB(255, 61, 133, 64);
      } else {
        color = const Color.fromARGB(255, 100, 21, 15);
      }
      return TableRow(children: [
        TableCell(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(edcSummary.paymentTypeName),
        )),
        if (setting.canShow('edcSettlement', 'diff_amount'))
          TableCell(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(edcSummary.totalInSystem.toString()),
          )),
        TableCell(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(edcSummary.totalInInput.toString()),
        )),
        TableCell(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            edcSummary.status.humanize(),
            style: TextStyle(color: color),
          ),
        )),
      ]);
    }).toList();
  }

  void _checkEdc() async {
    edcSummaries = [];
    server
        .get(
            'cashier_sessions/${widget.cashierSession.id}/edc_settlements/check_edc')
        .then((response) {
      if (response.statusCode == 200) {
        final json = response.data;
        setState(() {
          _displaySummary = true;
          for (final row in json['data']) {
            final attributes = row['attributes'];
            edcSummaries.add(EdcSummary(
                paymentTypeName: attributes['payment_type_name'],
                status: EdcSummaryStatus.fromString(attributes['status']),
                totalInSystem: Money.tryParse(attributes['total_in_system']) ??
                    const Money(0),
                totalInInput: Money.tryParse(attributes['total_in_input']) ??
                    const Money(0)));
          }
        });
      }
    }, onError: (error) {
      defaultErrorResponse(error: error);
      _displaySummary = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tanggal : ${dateFormat(widget.cashierSession.date)}'),
              const SizedBox(
                height: 10,
              ),
              Form(
                key: _formKey,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    child: Table(
                        border: TableBorder.all(width: 2),
                        columnWidths: const {
                          0: FixedColumnWidth(250),
                          1: FixedColumnWidth(250),
                          2: FixedColumnWidth(250),
                          3: FixedColumnWidth(250),
                          4: FixedColumnWidth(250),
                          5: FixedColumnWidth(250),
                          6: FixedColumnWidth(100),
                        },
                        children: [
                              TableRow(
                                  children: _headerTable(),
                                  decoration: const BoxDecoration()),
                            ] +
                            edcSettlements
                                .map<TableRow>(
                                    (edcSettlement) => _rowForm(edcSettlement))
                                .toList()),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: IconButton.filled(
                    focusNode: _focusNode,
                    onPressed: () {
                      setState(() {
                        edcSettlements.add(EdcSettlement(
                            cashierSession: widget.cashierSession));
                      });
                    },
                    icon: const Icon(Icons.add)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          _submitEdcs();
                        },
                        child: const Text('Submit')),
                    const SizedBox(
                      width: 25,
                    ),
                    Visibility(
                      visible: setting.isAuthorize('edcSettlement', 'checkEdc'),
                      child: ElevatedButton(
                          onPressed: () {
                            _checkEdc();
                          },
                          child: const Text('Cek EDC')),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: _displaySummary,
                child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Table(
                      border: TableBorder.all(),
                      children: [
                            TableRow(children: [
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Tipe Pembayaran',
                                    style: _headerStyle,
                                  ),
                                ),
                              ),
                              if (setting.canShow(
                                  'edcSettlement', 'diff_amount'))
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Total di system',
                                      style: _headerStyle,
                                    ),
                                  ),
                                ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Hasil EDC Settlement',
                                    style: _headerStyle,
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Status',
                                    style: _headerStyle,
                                  ),
                                ),
                              ),
                            ]),
                          ] +
                          _summaryRows(),
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }
}

enum EdcSummaryStatus {
  same,
  lesser,
  greater;

  String humanize() {
    switch (this) {
      case same:
        return 'Pas';
      case lesser:
        return 'Kurang';
      case greater:
        return 'Lebih';
    }
  }

  static EdcSummaryStatus fromString(String value) {
    switch (value) {
      case 'same':
        return same;
      case 'lesser':
        return lesser;
      case 'greater':
        return greater;
      default:
        throw "$value is not edc summary status";
    }
  }
}

class EdcSummary {
  String paymentTypeName;
  Money totalInSystem;
  Money totalInInput;
  EdcSummaryStatus status;
  EdcSummary(
      {required this.paymentTypeName,
      required this.totalInSystem,
      required this.totalInInput,
      required this.status});
}

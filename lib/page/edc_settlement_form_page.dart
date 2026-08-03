import 'package:fe_pos/model/cashier_session.dart';
import 'package:fe_pos/model/edc_settlement.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/authorizer_form_field.dart';
import 'package:fe_pos/widget/money_form_field.dart';
import 'package:fe_pos/widget/table_form.dart';
import 'package:flutter/material.dart';
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
  late final Authorizer setting;
  late Flash flash;
  List<EdcSettlement> edcSettlements = [];
  bool _displaySummary = false;
  final _focusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  final _headerStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  final ValueNotifier<bool> notifier = ValueNotifier(false);
  @override
  bool get wantKeepAlive => true;

  CashierSession get cashierSession => widget.cashierSession;

  @override
  void initState() {
    flash = Flash();
    server = context.read<Server>();
    setting = context.read<Authorizer>();
    super.initState();
    _focusNode.requestFocus();
    Future.delayed(Duration.zero, fetchEdcSettlement);
  }

  void fetchEdcSettlement() {
    showLoadingPopup();
    server
        .get(
          'cashier_sessions/${cashierSession.id}/edc_settlements',
          queryParam: {
            'include': 'payment_type,payment_provider,cashier_session',
            'fields[payment_type]': 'name',
            'fields[payment_provider]': 'name',
            'page[page]': '1',
            'page[limit]': '999999',
          },
        )
        .then((response) {
          if (response.statusCode == 200) {
            final jsonData = response.data['data'];
            setState(() {
              edcSettlements = jsonData
                  .map<EdcSettlement>(
                    (json) => EdcSettlementClass().fromJson(
                      json,
                      included: response.data['included'] ?? [],
                    ),
                  )
                  .toList();
            });
          }
        }, onError: (error) => defaultErrorResponse(error: error))
        .whenComplete(() => hideLoadingPopup());
  }

  void _removeEdcSettlement(EdcSettlement edcSettlement) {
    setState(() {
      if (edcSettlement.isNewRecord) {
        edcSettlements.remove(edcSettlement);
      } else {
        edcSettlement.flagDestroy();
      }
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
        'attributes': cashierSession,
        'relationships': {
          'edc_settlements': {
            'data': cashierSession.edcSettlements
                .map<Map>(
                  (edcSettlement) => {
                    'id': edcSettlement.id,
                    'type': 'edc_settlement',
                    'attributes': edcSettlement,
                  },
                )
                .toList(),
          },
        },
      },
    };
    server
        .put(
          'cashier_sessions/${cashierSession.id.toString()}',
          body: bodyParam,
        )
        .then((response) {
          if (response.statusCode == 200) {
            flash.show(
              const Text('Berhasil disimpan'),
              ToastificationType.success,
            );
            fetchEdcSettlement();
          } else {
            var data = response.data;
            flash.showBanner(
              title: data['message'],
              description: (data['errors'] ?? []).join('\n'),
              messageType: ToastificationType.error,
            );
          }
        }, onError: (error) {})
        .whenComplete(() => hideLoadingPopup());
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
      return TableRow(
        children: [
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(edcSummary.paymentTypeName),
            ),
          ),
          if (setting.canShow('edcSettlement', 'diff_amount'))
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(edcSummary.totalInSystem.format()),
              ),
            ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(edcSummary.totalInInput.format()),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                edcSummary.status.humanize(),
                style: TextStyle(color: color),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  void _checkEdc() async {
    edcSummaries = [];
    server
        .get(
          'cashier_sessions/${widget.cashierSession.id}/edc_settlements/check_edc',
        )
        .then(
          (response) {
            if (response.statusCode == 200) {
              final json = response.data;
              setState(() {
                _displaySummary = true;
                for (final row in json['data']) {
                  final attributes = row['attributes'];
                  edcSummaries.add(
                    EdcSummary(
                      paymentTypeName: attributes['payment_type_name'],
                      status: EdcSummaryStatus.fromString(attributes['status']),
                      totalInSystem:
                          Money.tryParse(attributes['total_in_system']) ??
                          const Money(0),
                      totalInInput:
                          Money.tryParse(attributes['total_in_input']) ??
                          const Money(0),
                    ),
                  );
                }
              });
            }
          },
          onError: (error) {
            defaultErrorResponse(error: error);
            _displaySummary = false;
          },
        );
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
              const SizedBox(height: 10),
              Form(
                key: _formKey,
                child: TableForm<EdcSettlement>(
                  columns: [
                    TableFormColumn(
                      title: setting.columnName(
                        'edcSettlement',
                        'payment_provider_id',
                      ),
                      headerBuilder: (context) => Text(
                        setting.columnName(
                          'edcSettlement',
                          'payment_provider_id',
                        ),
                        style: _headerStyle,
                      ),
                      rowBuilder: (context, edcSettlement, index) =>
                          AsyncDropdown<PaymentProvider>(
                            allowClear: false,
                            textOnSearch: (paymentProvider) =>
                                paymentProvider.name,
                            selected: edcSettlement.paymentProvider,
                            modelClass: PaymentProviderClass(),
                            request: (QueryRequest queryRequest) {
                              queryRequest.filters.add(
                                ComparisonFilterData(
                                  key: 'status',
                                  operator: .equals,
                                  value: PaymentProviderStatus.active
                                      .toString(),
                                ),
                              );
                              return PaymentProviderClass().finds(
                                server,
                                queryRequest,
                              );
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
                    ),
                    TableFormColumn(
                      title: setting.columnName(
                        'edcSettlement',
                        'payment_type_id',
                      ),
                      headerBuilder: (context) => Text(
                        setting.columnName('edcSettlement', 'payment_type_id'),
                        style: _headerStyle,
                      ),
                      rowBuilder: (context, edcSettlement, index) =>
                          AsyncDropdown<PaymentType>(
                            allowClear: false,
                            textOnSearch: (paymentType) => paymentType.name,
                            selected: edcSettlement.paymentType,
                            modelClass: PaymentTypeClass(),
                            onChanged: (paymentType) {
                              edcSettlement.paymentType =
                                  paymentType ?? PaymentType();
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'harus diisi';
                              }
                              return null;
                            },
                          ),
                    ),
                    TableFormColumn(
                      title: setting.columnName('edcSettlement', 'amount'),
                      headerBuilder: (context) => Text(
                        setting.columnName('edcSettlement', 'amount'),
                        style: _headerStyle,
                      ),
                      rowBuilder: (context, edcSettlement, index) =>
                          MoneyFormField(
                            initialValue: edcSettlement.amount,
                            onChanged: (value) {
                              edcSettlement.amount = value ?? const Money(0);
                            },
                          ),
                    ),
                    TableFormColumn(
                      title: setting.columnName('edcSettlement', 'terminal_id'),
                      headerBuilder: (context) => Text(
                        setting.columnName('edcSettlement', 'terminal_id'),
                        style: _headerStyle,
                      ),
                      rowBuilder: (context, edcSettlement, index) =>
                          AsyncDropdown<PaymentProviderEdc>(
                            textOnSearch: (data) => data.terminalId,
                            allowClear: false,
                            selected: PaymentProviderEdc(
                              terminalId: edcSettlement.terminalId,
                              merchantId: edcSettlement.merchantId,
                            ),
                            modelClass: PaymentProviderEdcClass(),
                            onChanged: (data) {
                              setState(() {
                                edcSettlement.terminalId =
                                    data?.terminalId ?? '';
                                edcSettlement.merchantId =
                                    data?.merchantId ?? '';
                                notifier.toggle();
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'harus diisi';
                              }
                              return null;
                            },
                            request: (QueryRequest queryRequest) {
                              queryRequest.filters.add(
                                ComparisonFilterData(
                                  key: 'payment_provider_id',
                                  value: edcSettlement.paymentProviderId,
                                ),
                              );
                              return PaymentProviderEdcClass().finds(
                                server,
                                queryRequest,
                              );
                            },
                          ),
                    ),
                    TableFormColumn(
                      title: setting.columnName('edcSettlement', 'merchant_id'),
                      headerBuilder: (context) => Text(
                        setting.columnName('edcSettlement', 'merchant_id'),
                        style: _headerStyle,
                      ),
                      rowBuilder: (context, edcSettlement, index) =>
                          AuthorizerFormField(
                            tableName: 'edcSettlement',
                            columnName: 'merchant_id',
                            notifier: notifier,
                            valueCallback: () => edcSettlement.merchantId,
                            childBuilder: (textController) {
                              return TextFormField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                controller: textController,
                                readOnly: true,
                              );
                            },
                          ),
                    ),
                    if (setting.canShow('edcSettlement', 'status'))
                      TableFormColumn(
                        title: setting.columnName('edcSettlement', 'status'),
                        headerBuilder: (context) => Text(
                          setting.columnName('edcSettlement', 'status'),
                          style: _headerStyle,
                        ),
                        rowBuilder: (context, edcSettlement, index) =>
                            DropdownMenu<EdcSettlementStatus>(
                              width: 220,
                              initialSelection: edcSettlement.status,
                              onSelected: (value) => edcSettlement.status =
                                  value ?? edcSettlement.status,
                              dropdownMenuEntries: EdcSettlementStatus.values
                                  .map<DropdownMenuEntry<EdcSettlementStatus>>(
                                    (status) =>
                                        DropdownMenuEntry<EdcSettlementStatus>(
                                          value: status,
                                          label: status.humanize(),
                                        ),
                                  )
                                  .toList(),
                            ),
                      ),
                  ],
                  actionColumn: TableFormColumn(
                    headerBuilder: (context) => IconButton.filled(
                      focusNode: _focusNode,
                      onPressed: () {
                        setState(() {
                          edcSettlements.add(
                            EdcSettlement(
                              cashierSession: widget.cashierSession,
                            ),
                          );
                        });
                      },
                      icon: const Icon(Icons.add),
                    ),
                    rowBuilder: (context, edcSettlement, index) => IconButton(
                      iconSize: 35,
                      onPressed: () => _removeEdcSettlement(edcSettlement),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  rows: edcSettlements,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: IconButton.filled(
                  focusNode: _focusNode,
                  onPressed: () {
                    setState(() {
                      edcSettlements.add(
                        EdcSettlement(cashierSession: widget.cashierSession),
                      );
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
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
                      child: const Text('Submit'),
                    ),
                    const SizedBox(width: 25),
                    Visibility(
                      visible: setting.isAuthorize(
                        'edc_settlements',
                        'checkEdc',
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          _checkEdc();
                        },
                        child: const Text('Cek EDC'),
                      ),
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
                    children:
                        [
                          TableRow(
                            children: [
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
                                'edcSettlement',
                                'diff_amount',
                              ))
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
                                  child: Text('Status', style: _headerStyle),
                                ),
                              ),
                            ],
                          ),
                        ] +
                        _summaryRows(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum EdcSummaryStatus implements EnumTranslation {
  same,
  lesser,
  greater;

  @override
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
  EdcSummary({
    required this.paymentTypeName,
    required this.totalInSystem,
    required this.totalInInput,
    required this.status,
  });
}

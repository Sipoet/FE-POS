import 'package:fe_pos/model/cashier_session.dart';
import 'package:fe_pos/model/edc_settlement.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EdcSettlementFormPage extends StatefulWidget {
  final CashierSession cashierSession;
  const EdcSettlementFormPage({super.key, required this.cashierSession});

  @override
  State<EdcSettlementFormPage> createState() => _EdcSettlementFormPageState();
}

class _EdcSettlementFormPageState extends State<EdcSettlementFormPage>
    with DefaultResponse {
  late final Server server;
  late final Setting setting;
  final Map<EdcSettlement, Widget> _statusSettlementIcon = {};
  List<EdcSettlement> edcSettlements = [];
  @override
  void initState() {
    server = context.read<Server>();
    setting = context.read<Setting>();
    super.initState();
  }

  void fetchEdcSettlement() {
    server.get('cashier_sessions/${widget.cashierSession.id}/edc_settlements',
        queryParam: {
          'include': 'payment_type,payment_provider'
        }).then((response) {
      if (response.statusCode == 200) {
        final jsonData = response.data['data'];
        edcSettlements = jsonData
            .map<EdcSettlement>((json) => EdcSettlement.fromJson(json,
                included: response.data['include']))
            .toList();
      }
    }, onError: (error) => defaultErrorResponse(error: error));
  }

  List<TableCell> _headerTable() {
    return [
      TableCell(
          child: Text(setting.columnName('edcSettlement', 'payment_provider'))),
      TableCell(
          child: Text(setting.columnName('edcSettlement', 'payment_type'))),
      TableCell(child: Text(setting.columnName('edcSettlement', 'amount'))),
      TableCell(
          child: Text(setting.columnName('edcSettlement', 'terminal_id'))),
      TableCell(
          child: Text(setting.columnName('edcSettlement', 'merchant_id'))),
      const TableCell(child: Text('Status')),
    ];
  }

  TableRow _rowForm(EdcSettlement edcSettlement) {
    final textController =
        TextEditingController(text: edcSettlement.merchantId.toString());
    return TableRow(children: [
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AsyncDropdown<PaymentProvider>(
          allowClear: false,
          textOnSearch: (paymentProvider) => paymentProvider.code,
          selected: edcSettlement.paymentProvider,
          converter: PaymentProvider.fromJson,
          path: 'payment_providers',
          onChanged: (paymentProvider) {
            edcSettlement.paymentProvider =
                paymentProvider ?? PaymentProvider();
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
            path: 'payment_types'),
      )),
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          decoration: const InputDecoration(border: OutlineInputBorder()),
          initialValue: edcSettlement.amount.toString(),
          onChanged: (value) {
            edcSettlement.amount = Money.tryParse(value) ?? const Money(0);
          },
        ),
      )),
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AsyncDropdown<Map<String, dynamic>>(
          textOnSearch: (data) => data['terminal_id'].toString(),
          selected: {
            'terminal_id': edcSettlement.terminalId,
            'merchant_id': edcSettlement.merchantId
          },
          converter: (data, {included = const []}) => data,
          onChanged: (data) {
            setState(() {
              edcSettlement.terminalId = data?['terminal_id'] ?? '';
              edcSettlement.merchantId = data?['merchant_id'] ?? '';
              textController.text = edcSettlement.merchantId;
            });
          },
          request: (server, page, searchText, cancelToken) {
            return server.get('payment_provider_edcs',
                queryParam: {
                  'page': page,
                  'search_text': searchText,
                  'filter[payment_provider_id][eq]':
                      edcSettlement.paymentProvider.id
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
          child: _statusSettlementIcon[edcSettlement] ?? const SizedBox()),
    ]);
  }

  void _submitEdcs() {
    for (EdcSettlement edcSettlement in edcSettlements) {
      _saveEdc(edcSettlement);
    }
  }

  void _saveEdc(EdcSettlement edcSettlement) {
    Future response;
    final bodyParam = {
      'data': {
        'type': 'edc_settlement',
        'attributes': edcSettlement.toJson(),
      }
    };
    if (edcSettlement.id == null) {
      response = server.post('edc_settlements', body: bodyParam);
    } else {
      response = server.post('edc_settlements/${edcSettlement.id.toString()}',
          body: bodyParam);
    }
    response.then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        EdcSettlement.fromJson(response.data['data'],
            model: edcSettlement, included: response.data['included']);
        setState(() {
          _statusSettlementIcon[edcSettlement] = const Icon(
            Icons.check,
            color: Colors.green,
          );
        });
      } else {
        setState(() {
          _statusSettlementIcon[edcSettlement] = Tooltip(
            message: response.data['message'] ?? 'gagal',
            child: const Icon(
              Icons.error,
              color: Colors.red,
            ),
          );
        });
      }
    }, onError: (error) {
      setState(() {
        _statusSettlementIcon[edcSettlement] = Tooltip(
          message: error.toString(),
          child: const Icon(
            Icons.error,
            color: Colors.red,
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: 900,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
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
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: IconButton.filled(
                      onPressed: () {
                        setState(() {
                          edcSettlements.add(EdcSettlement(
                              cashierSessionId: widget.cashierSession.id));
                        });
                      },
                      icon: const Icon(Icons.add)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ElevatedButton(
                      onPressed: () {
                        _submitEdcs();
                      },
                      child: const Text('Submit')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

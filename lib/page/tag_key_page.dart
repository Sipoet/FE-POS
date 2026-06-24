import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/page/tag_key_form_page.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/model/tag_key.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';

class TagKeyPage extends StatefulWidget {
  const TagKeyPage({super.key});

  @override
  State<TagKeyPage> createState() => _TagKeyPageState();
}

class _TagKeyPageState extends State<TagKeyPage> with DefaultResponse {
  late final TableController _source;
  late final Server server;
  final cancelToken = CancelToken();
  late Flash flash;
  late final List<TableColumn> columns;
  List<FilterData> _filter = [];

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    final setting = context.read<Authorizer>();

    columns = setting.tableColumn('tagKey');
    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  void openForm(TagKey tagKey) {
    final tabManager = context.read<TabManager>();

    final desc = tagKey.isNewRecord ? 'Tambah' : 'Edit';
    tabManager.addTab(
      '$desc Tag Key ${tagKey.id ?? ''}',
      TagKeyFormPage(tagKey: tagKey),
    );
  }

  void deleteRecord(TagKey tagKey) {
    showConfirmDialog(
      message: 'Apakah Yakin Hapus Tag Key ${tagKey.name}',
      onSubmit: () {
        tagKey.destroy(server).then((result) {
          if (result) {
            flash.show(Text('Sukses hapus ${tagKey.name}'), .success);
            refreshTable();
          } else {
            flash.show(Text('Gagal hapus ${tagKey.name}'), .error);
          }
        });
      },
    );
  }

  void refreshTable() {
    _source.refreshTable();
  }

  Future<DataTableResponse<TagKey>> fetchData(QueryRequest request) {
    _source.setShowLoading(true);
    request.cancelToken = cancelToken;
    request.filters.addAll(_filter);

    return TagKeyClass()
        .finds(server, request)
        .then(
          (response) {
            return DataTableResponse<TagKey>(
              totalPage: response.metadata['total_pages'],
              models: response.models,
            );
          },
          onError: (error, stackTrace) {
            defaultErrorResponse(error: error);
            return DataTableResponse<TagKey>(totalPage: 1, models: []);
          },
        )
        .whenComplete(() => _source.setShowLoading(false));
  }

  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
      child: Column(
        children: [
          TableFilterForm(
            columns: columns,
            onSubmit: (filter) {
              _filter = filter;
              _source.refreshTable();
            },
          ),
          SizedBox(
            height: bodyScreenHeight,
            child: CustomAsyncDataTable<TagKey>(
              additionalHeaderActions: (menuController) => [
                MenuItemButton(
                  child: const Text('Tambah Tag Key'),
                  onPressed: () {
                    menuController.close();
                    openForm(TagKey());
                  },
                ),
              ],
              rowAction: (model) => Row(
                children: [
                  IconButton(
                    onPressed: () => openForm(model),
                    icon: Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () => deleteRecord(model),
                    icon: Icon(Icons.delete),
                  ),
                ],
              ),
              onLoaded: (stateManager) => _source = stateManager,
              showFilter: false,
              showSummary: false,
              fixedLeftColumns: 1,
              fetchData: fetchData,
              columns: columns,
            ),
          ),
        ],
      ),
    );
  }
}

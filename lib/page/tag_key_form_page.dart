import 'package:collection/collection.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/model/tag_key.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:provider/provider.dart';

class TagKeyFormPage extends StatefulWidget {
  final TagKey tagKey;
  const TagKeyFormPage({super.key, required this.tagKey});

  @override
  State<TagKeyFormPage> createState() => _TagKeyFormPageState();
}

class _TagKeyFormPageState extends State<TagKeyFormPage>
    with DefaultResponse, LoadingPopup, HistoryPopup {
  late TagKey tagKey;
  final _formState = GlobalKey<FormState>();
  final Map<int, FocusNode> _focusNodes = {};
  String _searchValue = '';
  late final Server _server;
  late final TabManager _tabManager;
  final flash = Flash();
  bool _showForm = true;
  @override
  void initState() {
    tagKey = widget.tagKey;
    _server = context.read<Server>();
    _tabManager = context.read<TabManager>();
    super.initState();
    Future.delayed(Duration.zero, () {
      showLoadingPopup();
      tagKey
          .refresh(_server, include: ['tags'])
          .then(
            (result) => setState(() {
              tagKey.tags;
            }),
          )
          .whenComplete(hideLoadingPopup);
    });
  }

  void _saveRecord() {
    if (_formState.currentState?.validate() != true) {
      return;
    }
    _formState.currentState?.save();
    tagKey
        .save(
          _server,
          includeAttributes: {
            'tags_attributes': tagKey.tags.map((e) => e.asJson()).toList(),
          },
        )
        .then((result) {
          if (result) {
            setState(() {
              tagKey;
            });
            flash.show(Text('Sukses Simpan'), .success);
            _tabManager.changeTabHeader(widget, 'Edit Tag Key ${tagKey.id}');
          } else {
            debugPrint(tagKey.errors.join(','));
          }
        });
  }

  void _resetRecord() {
    showConfirmDialog(
      message: 'Apakah yakin reset Tag Key "${tagKey.name}"',
      onSubmit: () {
        setState(() {
          _showForm = false;
        });
        tagKey.reset();
        Future.delayed(Durations.short1, () {
          setState(() {
            _showForm = true;
          });
        });
      },
    );
  }

  void _duplicateRecord() {
    showConfirmDialog(
      message: 'Apakah yakin duplikat Tag Key "${tagKey.name}"',
      onSubmit: () {
        tagKey.id = null;
        for (final tag in tagKey.tags) {
          tag.id = null;
        }
        _tabManager.changeTabHeader(widget, 'Tambah Tag Key');
      },
    );
  }

  void _newRecord() {
    _tabManager.changeTabHeader(widget, 'Tambah Tag Key');
    setState(() {
      _showForm = false;
    });
    Future.delayed(Durations.short1, () {
      tagKey = TagKeyClass().initModel();
      setState(() {
        _showForm = true;
      });
    });
  }

  void _addTag() {
    final tag = Tag(tagKey: tagKey);
    _focusNodes[tagKey.tags.length] = FocusNode();
    setState(() {
      tagKey.tags.add(tag);
      Future.delayed(
        Duration.zero,
        () => _focusNodes[tagKey.tags.length - 1]?.requestFocus(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: .all(10),
        child: Form(
          key: _formState,
          autovalidateMode: .onUnfocus,
          child: Visibility(
            visible: _showForm,
            child: Column(
              children: [
                Expanded(
                  child: VerticalBodyScroll(
                    child: Column(
                      spacing: 10,
                      crossAxisAlignment: .start,
                      children: [
                        Visibility(
                          visible: !tagKey.isNewRecord,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                fetchHistoryByRecord('Tag Key', tagKey.id),
                            label: const Text('Riwayat'),
                            icon: const Icon(Icons.history),
                          ),
                        ),
                        TextFormField(
                          initialValue: tagKey.name,
                          onChanged: (value) => tagKey.name = value,
                          decoration: InputDecoration(
                            label: Text(
                              'Nama*',
                              style: DefaultResponse.labelStyle,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'harus diisi';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          initialValue: tagKey.group,
                          onChanged: (value) => tagKey.group = value,
                          decoration: InputDecoration(
                            label: Text(
                              'Grup',
                              style: DefaultResponse.labelStyle,
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        Row(
                          mainAxisAlignment: .spaceBetween,
                          children: [
                            Row(
                              spacing: 10,
                              children: [
                                Text(
                                  'Nilai Tag*:',
                                  style: DefaultResponse.labelStyle,
                                ),
                                SizedBox(
                                  width: 180,
                                  child: TextField(
                                    onChanged: (value) => setState(() {
                                      _searchValue = value;
                                    }),
                                    decoration: InputDecoration(
                                      hintText: 'Search',
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            LayoutBuilder(
                              builder: (context, constraint) {
                                final width = MediaQuery.of(context).size.width;
                                if (width < 500) {
                                  return IconButton.filled(
                                    onPressed: _addTag,
                                    icon: Icon(Icons.add),
                                  );
                                }
                                return ElevatedButton.icon(
                                  onPressed: _addTag,
                                  label: Text('Tambah Tag'),
                                  icon: Icon(Icons.add),
                                );
                              },
                            ),
                          ],
                        ),

                        ...tagKey.tags.reversed
                            .where(
                              (e) =>
                                  (e.value.isEmpty ||
                                      e.value.contains(_searchValue)) &&
                                  !e.isDestroyed,
                            )
                            .mapIndexed<Widget>(
                              (index, tag) => Row(
                                key: ObjectKey(tag),
                                spacing: 15,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      focusNode:
                                          _focusNodes[tagKey.tags.length -
                                              index -
                                              1],
                                      initialValue: tag.value,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'value',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'harus diisi';
                                        }
                                        return null;
                                      },
                                      onChanged: (value) => setState(() {
                                        tag.value = value;
                                      }),
                                    ),
                                  ),
                                  IconButton.filled(
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red.shade300,
                                      hoverColor: Colors.red.shade500,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (tag.isNewRecord) {
                                          tagKey.tags.remove(tag);
                                        } else {
                                          tag.flagDestroy();
                                        }
                                      });
                                    },
                                    icon: Icon(Icons.close),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 10),
                Wrap(
                  runSpacing: 15,
                  spacing: 15,
                  children: [
                    ElevatedButton(
                      onPressed: _saveRecord,
                      child: Text('Simpan'),
                    ),
                    ElevatedButton(
                      onPressed: _resetRecord,
                      child: Text('Reset'),
                    ),
                    if (!tagKey.isNewRecord)
                      ElevatedButton(
                        onPressed: _newRecord,
                        child: Text('Buat Baru'),
                      ),
                    if (!tagKey.isNewRecord)
                      ElevatedButton(
                        onPressed: _duplicateRecord,
                        child: Text('Menduplikasi'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

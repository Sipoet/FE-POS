import 'package:fe_pos/model/brand.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BrandFormPage extends StatefulWidget {
  final Brand brand;
  const BrandFormPage({super.key, required this.brand});

  @override
  State<BrandFormPage> createState() => _BrandFormPageState();
}

class _BrandFormPageState extends State<BrandFormPage> {
  Brand get brand => widget.brand;
  late final Setting _setting;
  @override
  void initState() {
    _setting = context.read<Setting>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
      child: Column(
        children: [
          TextFormField(
            initialValue: brand.name,
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('brand', 'name')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            initialValue: brand.description,
            readOnly: true,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
                label: Text(_setting.columnName('brand', 'description')),
                border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}

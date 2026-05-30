import 'package:fe_pos/tool/custom_type.dart';
import 'package:flutter/material.dart';

class EnumDropdown<T extends EnumTranslation> extends StatelessWidget {
  final List<T> values;
  final Widget? label;
  final T? initialSelection;
  final void Function(T? values)? onChanged;
  final bool allowClear;
  final bool? isDense;
  final double? width;
  const EnumDropdown({
    super.key,
    this.label,
    this.isDense,
    this.width,
    this.initialSelection,
    this.allowClear = false,
    required this.values,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<T>(
      width: width,
      label: label,
      onSelected: onChanged,
      initialSelection: initialSelection,
      inputDecorationTheme: InputDecorationTheme(
        isDense: isDense,
        border: OutlineInputBorder(),
      ),
      dropdownMenuEntries: values
          .map<DropdownMenuEntry<T>>(
            (value) =>
                DropdownMenuEntry<T>(value: value, label: value.humanize()),
          )
          .toList(),
    );
  }
}

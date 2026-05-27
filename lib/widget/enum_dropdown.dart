import 'package:fe_pos/tool/custom_type.dart';
import 'package:flutter/material.dart';

class EnumDropdown<T extends EnumTranslation> extends StatefulWidget {
  final List<T> values;
  final Widget? label;
  final T? initialSelection;
  final void Function(T? values)? onChanged;
  final bool allowClear;
  final bool? isDense;
  const EnumDropdown({
    super.key,
    this.label,
    this.isDense,
    this.initialSelection,
    this.allowClear = false,
    required this.values,
    this.onChanged,
  });

  @override
  State<EnumDropdown<T>> createState() => _EnumDropdownState<T>();
}

class _EnumDropdownState<T extends EnumTranslation>
    extends State<EnumDropdown<T>> {
  @override
  Widget build(BuildContext context) {
    return DropdownMenu<T>(
      label: widget.label,
      onSelected: widget.onChanged,
      initialSelection: widget.initialSelection,
      inputDecorationTheme: InputDecorationTheme(
        isDense: widget.isDense,
        border: OutlineInputBorder(),
      ),
      dropdownMenuEntries: widget.values
          .map<DropdownMenuEntry<T>>(
            (value) =>
                DropdownMenuEntry<T>(value: value, label: value.humanize()),
          )
          .toList(),
    );
  }
}

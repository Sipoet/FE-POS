import 'package:fe_pos/tool/custom_type.dart';
import 'package:flutter/material.dart';

class TimeFormField extends StatefulWidget {
  final TimeOfDay? initialValue;
  final Widget? label;
  final TimeOfDay? firstDate;
  final TimeOfDay? lastDate;
  final bool canRemove;
  final FocusNode? focusNode;
  final String? helpText;
  final TextEditingController? controller;
  final void Function(TimeOfDay?)? onSaved;
  final void Function(TimeOfDay? date)? onChanged;
  final String? Function(TimeOfDay?)? validator;
  const TimeFormField(
      {super.key,
      this.label,
      this.controller,
      this.firstDate,
      this.lastDate,
      this.onSaved,
      this.helpText,
      this.focusNode,
      this.onChanged,
      this.validator,
      this.canRemove = false,
      this.initialValue});

  @override
  State<TimeFormField> createState() => _TimeFormFieldState();
}

/// RestorationProperty objects can be used because of RestorationMixin.
class _TimeFormFieldState extends State<TimeFormField> {
  // In this example, the restoration ID for the mixin is passed in through
  // the [StatefulWidget]'s constructor.

  TimeOfDay? _date;

  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    widget.controller?.addListener(() {
      _controller.text = widget.controller!.text;
      _date = TimeDay.parse(widget.controller!.text);
    });
    if (widget.initialValue != null) {
      _date = widget.initialValue;
    } else if (widget.controller != null) {
      _date = TimeDay.parse(widget.controller!.text);
    }
    _controller.text =
        _date == null ? '' : (_date ?? TimeOfDay.now()).format24Hour();

    super.initState();
  }

  void _selectDate(TimeOfDay? newSelectedDate) {
    if (widget.onChanged != null) {
      widget.onChanged!(newSelectedDate);
    }
    if (newSelectedDate != null) {
      setState(() {
        _date = newSelectedDate;
        _controller.text = newSelectedDate.format24Hour();
      });
    }
  }

  void _showDialog() {
    showTimePicker(
      context: context,
      initialTime: _date ?? TimeOfDay.now(),
      helpText: widget.helpText,
      hourLabelText: 'Jam',
      minuteLabelText: 'Menit',
      cancelText: 'Batal',
      confirmText: 'OK',
    ).then((value) {
      final time = value;
      _selectDate(time);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onTap: () {
        _showDialog();
      },
      focusNode: widget.focusNode,
      readOnly: true,
      validator: (value) {
        if (widget.validator == null) {
          return null;
        }
        return widget.validator!(_date);
      },
      onSaved: widget.onSaved == null
          ? null
          : (newValue) {
              widget.onSaved!(_date);
            },
      decoration: InputDecoration(
        label: widget.label,
        contentPadding: const EdgeInsets.all(5),
        border: const OutlineInputBorder(),
        suffix: widget.canRemove && _date != null
            ? IconButton(
                iconSize: 30,
                onPressed: () {
                  setState(() {
                    _controller.text = '';
                    _date = null;
                  });
                  if (widget.onChanged != null) {
                    widget.onChanged!(_date);
                  }
                },
                icon: const Icon(Icons.close))
            : null,
      ),
      controller: _controller,
    );
  }
}

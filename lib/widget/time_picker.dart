import 'package:adoptive_calendar/adoptive_calendar.dart';
import 'package:fe_pos/tool/custom_type.dart';
import 'package:flutter/material.dart';

class TimePicker extends StatefulWidget {
  final TimeDay? initialValue;
  final Widget? label;
  final TimeDay? firstDate;
  final TimeDay? lastDate;
  final bool canRemove;
  final String? labelString;
  final void Function(TimeDay?)? onSaved;
  final void Function(TimeDay? date)? onChanged;
  final String? Function(TimeDay?)? validator;
  const TimePicker(
      {super.key,
      this.label,
      this.firstDate,
      this.lastDate,
      this.onSaved,
      this.labelString,
      this.onChanged,
      this.validator,
      this.canRemove = false,
      required this.initialValue});

  @override
  State<TimePicker> createState() => _TimePickerState();
}

/// RestorationProperty objects can be used because of RestorationMixin.
class _TimePickerState extends State<TimePicker> {
  // In this example, the restoration ID for the mixin is passed in through
  // the [StatefulWidget]'s constructor.

  TimeDay? _date;

  final _controller = TextEditingController();

  @override
  void initState() {
    _date = widget.initialValue;
    _controller.text = widget.initialValue == null
        ? ''
        : (widget.initialValue ?? TimeDay.now()).format24Hour();

    super.initState();
  }

  void _selectDate(TimeDay? newSelectedDate) {
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
      initialTime: _date ?? TimeDay.now(),
      helpText: widget.labelString,
    ).then((value) {
      final time = TimeDay.fromTimeOfDay(value);
      _selectDate(time);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Stack(children: [
          TextFormField(
            onTap: () {
              _showDialog();
            },
            readOnly: true,
            validator: (value) {
              if (widget.validator == null) {
                return null;
              }
              return widget.validator!(_date);
            },
            onSaved: (newValue) {
              widget.onSaved!(_date);
            },
            decoration: InputDecoration(
                label: widget.label, border: const OutlineInputBorder()),
            controller: _controller,
          ),
          Visibility(
              visible: widget.canRemove && _date != null,
              child: Positioned(
                top: 1,
                right: 5,
                child: IconButton(
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
                    icon: const Icon(Icons.close)),
              )),
        ]));
  }
}

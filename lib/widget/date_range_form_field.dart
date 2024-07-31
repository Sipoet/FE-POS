import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

class DateRangeFormField extends StatefulWidget {
  const DateRangeFormField({
    super.key,
    this.label,
    this.icon,
    this.textStyle,
    this.enabled = true,
    this.initialDateRange,
    this.datePickerOnly = false,
    this.onChanged,
    this.helpText,
    this.controller,
    this.focusNode,
    this.canRemove = false,
  });
  final Widget? label;
  final Widget? icon;
  final String? helpText;
  final TextStyle? textStyle;
  final DateTimeRange? initialDateRange;
  final bool enabled;
  final bool canRemove;
  final bool datePickerOnly;
  final FocusNode? focusNode;
  final Function(DateTimeRange? range)? onChanged;
  final PickerController? controller;
  @override
  State<DateRangeFormField> createState() => _DateRangeFormFieldState();
}

class _DateRangeFormFieldState extends State<DateRangeFormField> {
  late final TextEditingController _controller;
  late DateTimeRange? _dateRange = widget.initialDateRange;
  @override
  void initState() {
    _controller = TextEditingController(text: _daterangeFormat());
    widget.controller?.addListener(() {
      setState(() {
        _dateRange = widget.controller?.range ?? _dateRange;
        _controller.text = _daterangeFormat();
      });
    });
    super.initState();
  }

  String _daterangeFormat() {
    if (_dateRange == null) {
      return '';
    }
    var formater = DateFormat('dd/MM/y');
    if (_isSameDay(_dateRange!.start, _dateRange!.end)) {
      var hourFormat = DateFormat('HH:mm');
      return "${formater.format(_dateRange!.start)} ${hourFormat.format(_dateRange!.start)} - ${hourFormat.format(_dateRange!.end)}";
    }
    if (widget.datePickerOnly) {
      return "${formater.format(_dateRange!.start)} - ${formater.format(_dateRange!.end)}";
    } else {
      final formater = DateFormat('dd/MM/y HH:mm');
      return "${formater.format(_dateRange!.start)} - ${formater.format(_dateRange!.end)}";
    }
  }

  bool _isSameDay(DateTime start, DateTime end) {
    return start.day == end.day &&
        start.month == end.month &&
        start.year == end.year;
  }

  void _openDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final maxDate = DateTime(99999, 12, 31, 23, 59, 59, 59);

    showOmniDateTimeRangePicker(
      barrierColor: colorScheme.outline,
      context: context,
      is24HourMode: true,
      type: widget.datePickerOnly
          ? OmniDateTimePickerType.date
          : OmniDateTimePickerType.dateAndTime,
      title: widget.helpText != null ? Text(widget.helpText as String) : null,
      startWidget: const Text('Mulai'),
      endWidget: const Text('Akhir'),
      startFirstDate: DateTime(DateTime.now().year - 5),
      startLastDate: maxDate,
      endFirstDate: DateTime(DateTime.now().year - 5),
      endLastDate: maxDate,
      startInitialDate: _dateRange?.start,
      endInitialDate: _dateRange?.end,
    ).then(
      (pickedDateRange) {
        if (pickedDateRange == null) {
          return;
        }
        setState(() {
          if (pickedDateRange.length == 2) {
            _dateRange = DateTimeRange(
                start: pickedDateRange[0], end: pickedDateRange[1]);
          }
          _controller.text = _daterangeFormat();
          if (widget.onChanged != null) {
            widget.onChanged!(_dateRange);
          }
        });
        return;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(children: [
      TextFormField(
        focusNode: widget.focusNode,
        readOnly: true,
        style: widget.textStyle,
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(12),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    width: 2,
                    color: widget.enabled ? colorScheme.outline : Colors.grey)),
            border: OutlineInputBorder(
                borderSide: BorderSide(
                    width: 2,
                    color: widget.enabled ? colorScheme.outline : Colors.grey)),
            label: widget.label,
            icon: widget.icon),
        controller: _controller,
        onTap: () {
          if (!widget.enabled) return;
          _openDialog();
        },
      ),
      Visibility(
          visible: widget.canRemove && _dateRange != null,
          child: Positioned(
            top: 1,
            right: 5,
            child: IconButton(
                iconSize: 30,
                onPressed: () {
                  setState(() {
                    _controller.text = '';
                    _dateRange = null;
                  });
                  if (widget.onChanged != null) {
                    widget.onChanged!(_dateRange);
                  }
                },
                icon: const Icon(Icons.close)),
          )),
    ]);
  }
}

class PickerController extends ChangeNotifier {
  DateTimeRange range;
  PickerController(this.range);

  void changeDate(DateTimeRange newRange) {
    range = newRange;
    notifyListeners();
  }
}

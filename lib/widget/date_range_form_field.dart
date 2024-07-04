import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

class DateRangeFormField extends StatefulWidget {
  const DateRangeFormField(
      {super.key,
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
      this.format = 'dd/MM/y'});
  final Widget? label;
  final Widget? icon;
  final String? helpText;
  final TextStyle? textStyle;
  final DateTimeRange? initialDateRange;
  final String format;
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
    var formater = DateFormat(widget.format);
    if (_dateRange == null) {
      return '';
    }
    if (_isSameDay(_dateRange!.start, _dateRange!.end)) {
      var hourFormat = DateFormat('HH:mm');
      return "${formater.format(_dateRange!.start)} ${hourFormat.format(_dateRange!.start)} - ${hourFormat.format(_dateRange!.end)}";
    } else {
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
    showDateRangePicker(
      barrierColor: colorScheme.outline,
      initialEntryMode: DatePickerEntryMode.calendar,
      context: context,
      helpText: widget.helpText,
      cancelText: 'Batal',
      confirmText: 'OK',
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(99999, 12, 31, 23, 59, 59, 59),
      initialDateRange: _dateRange,
      locale: const Locale('id'),
    ).then(
      (pickedDateRange) {
        if (pickedDateRange is! DateTimeRange) {
          return;
        }
        if (widget.datePickerOnly) {
          setState(() {
            _dateRange = DateTimeRange(
                start: pickedDateRange.start,
                end: pickedDateRange.end
                    .copyWith(hour: 23, minute: 59, second: 59));

            _controller.text = _daterangeFormat();
            if (widget.onChanged != null) {
              widget.onChanged!(_dateRange);
            }
          });
          return;
        }
        showDialog<List<TimeOfDay>>(
          context: context,
          builder: (context) {
            return Wrap(
              children: [
                TimePickerDialog(
                  helpText: "Mulai Jam",
                  hourLabelText: 'Jam',
                  minuteLabelText: 'Menit',
                  cancelText: 'Batal',
                  confirmText: 'OK',
                  initialTime: TimeOfDay.fromDateTime(_dateRange!.start),
                  initialEntryMode: TimePickerEntryMode.dial,
                ),
                TimePickerDialog(
                  helpText: "Akhir Jam",
                  hourLabelText: 'Jam',
                  minuteLabelText: 'Menit',
                  cancelText: 'Batal',
                  confirmText: 'OK',
                  initialTime: TimeOfDay.fromDateTime(_dateRange!.end),
                  initialEntryMode: TimePickerEntryMode.dial,
                ),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK')),
              ],
            );
          },
        ).then((times) {
          if (times != null && times.length == 2) {
            final start = pickedDateRange.start
                .copyWith(hour: times[0].hour, minute: times[0].minute);
            final end = pickedDateRange.end
                .copyWith(hour: times[1].hour, minute: times[1].minute);
            _dateRange = DateTimeRange(start: start, end: end);
          }
        });
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

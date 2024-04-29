import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DateRangePicker extends StatefulWidget {
  const DateRangePicker(
      {super.key,
      this.label,
      this.icon,
      this.textStyle,
      this.enabled = true,
      this.initialDateRange,
      this.onChanged,
      this.controller,
      this.canRemove = false,
      this.format = 'dd/MM/y'});
  final Widget? label;
  final Widget? icon;
  final TextStyle? textStyle;
  final DateTimeRange? initialDateRange;
  final String format;
  final bool enabled;
  final bool canRemove;
  final Function(DateTimeRange? range)? onChanged;
  final PickerController? controller;
  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
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

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return Stack(children: [
      TextFormField(
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
        onTap: () async {
          if (!widget.enabled) return;
          DateTimeRange? pickedDateRange = await showDateRangePicker(
            barrierColor: colorScheme.outline,
            initialEntryMode: DatePickerEntryMode.calendarOnly,
            context: context,
            firstDate: DateTime(DateTime.now().year - 5),
            lastDate: DateTime(DateTime.now().year + 100),
            initialDateRange: _dateRange,
            locale: const Locale('id'),
          );
          if (pickedDateRange is! DateTimeRange) {
            return;
          }
          setState(() {
            _dateRange = DateTimeRange(
                start: pickedDateRange.start,
                end: pickedDateRange.end
                    .copyWith(hour: 23, minute: 59, second: 59));

            _controller.text = _daterangeFormat();
            if (widget.onChanged != null) {
              widget.onChanged!.call(_dateRange);
            }
          });
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

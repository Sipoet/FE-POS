import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DateRangePicker extends StatefulWidget {
  const DateRangePicker(
      {super.key,
      required this.label,
      required this.startDate,
      required this.endDate,
      this.onChanged,
      this.format = 'dd/MM/y HH:mm'});
  final Widget label;
  final DateTime startDate;
  final DateTime endDate;
  final String format;
  final Function? onChanged;
  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  late final TextEditingController _controller;
  late DateTimeRange _dateRange;
  @override
  void initState() {
    _controller = TextEditingController(text: _daterangeFormat());
    super.initState();
  }

  String _daterangeFormat() {
    var formater = DateFormat(widget.format);
    return "${formater.format(widget.startDate)} - ${formater.format(widget.endDate)}";
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
          label: widget.label, icon: const Icon(Icons.calendar_today_outlined)),
      keyboardType: TextInputType.datetime,
      controller: _controller,
      onTap: () async {
        DateTimeRange? pickedDateRange = await showDateRangePicker(
          barrierColor: colorScheme.outline,
          initialEntryMode: DatePickerEntryMode.calendarOnly,
          context: context,
          firstDate: DateTime(DateTime.now().year - 5),
          lastDate: DateTime(DateTime.now().year + 100),
          initialDateRange:
              DateTimeRange(start: widget.startDate, end: widget.endDate),
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
          if (widget.onChanged is Function) {
            widget.onChanged!.call(_dateRange);
          }
        });
      },
    );
  }
}

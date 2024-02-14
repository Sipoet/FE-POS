import 'package:fe_pos/tool/setting.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DatePicker<T> extends StatefulWidget {
  final T? initialValue;
  final Widget? label;
  final String? restorationId;
  final void Function(T date)? onChange;
  final DateTime? firstDate;
  final DateTime? lastDate;
  const DatePicker(
      {super.key,
      this.restorationId,
      this.label,
      this.onChange,
      this.firstDate,
      this.lastDate,
      required this.initialValue});

  @override
  State<DatePicker> createState() => _DatePickerState();
}

/// RestorationProperty objects can be used because of RestorationMixin.
class _DatePickerState extends State<DatePicker> with RestorationMixin {
  // In this example, the restoration ID for the mixin is passed in through
  // the [StatefulWidget]'s constructor.
  @override
  String? get restorationId => widget.restorationId;

  late final RestorableDateTime _selectedDate;
  final _controller = TextEditingController();
  late final Setting _setting;
  late final RestorableRouteFuture<DateTime?> _restorableDatePickerRouteFuture =
      RestorableRouteFuture<DateTime?>(
    onComplete: _selectDate,
    onPresent: (NavigatorState navigator, Object? arguments) {
      return navigator.restorablePush(
        _datePickerRoute,
        arguments: _selectedDate.value.millisecondsSinceEpoch,
      );
    },
  );

  @override
  void initState() {
    _setting = context.read<Setting>();
    _selectedDate = RestorableDateTime(widget.initialValue ?? DateTime.now());
    _controller.text = _setting.dateFormat(widget.initialValue ?? '');

    super.initState();
  }

  @pragma('vm:entry-point')
  Route<DateTime> _datePickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return DatePickerDialog(
          initialDate: widget.initialValue,
          restorationId: 'date_picker_dialog',
          initialEntryMode: DatePickerEntryMode.calendarOnly,
          firstDate: widget.firstDate ?? DateTime(2022),
          lastDate: widget.lastDate ?? DateTime(9999),
        );
      },
    );
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedDate, 'selected_date');
    registerForRestoration(
        _restorableDatePickerRouteFuture, 'date_picker_route_future');
  }

  void _selectDate(DateTime? newSelectedDate) {
    if (newSelectedDate != null) {
      if (widget.onChange != null) {
        widget.onChange!(newSelectedDate);
      }
      setState(() {
        _selectedDate.value = newSelectedDate;
        _controller.text = _setting.dateFormat(newSelectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          onTap: () {
            _restorableDatePickerRouteFuture.present();
          },
          decoration: InputDecoration(
              label: widget.label, border: const OutlineInputBorder()),
          controller: _controller,
        ));
  }
}

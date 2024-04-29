import 'package:fe_pos/tool/setting.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DatePicker extends StatefulWidget {
  final DateTime? initialValue;
  final Widget? label;
  final String? restorationId;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool canRemove;
  final void Function(DateTime?)? onSaved;
  final void Function(DateTime? date)? onChanged;
  final String? Function(DateTime?)? validator;
  const DatePicker(
      {super.key,
      this.restorationId,
      this.label,
      this.firstDate,
      this.lastDate,
      this.onSaved,
      this.onChanged,
      this.validator,
      this.canRemove = false,
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
  DateTime? _date;

  final _controller = TextEditingController();
  late final Setting _setting;

  @override
  void initState() {
    _setting = context.read<Setting>();
    _selectedDate = RestorableDateTime(widget.initialValue ?? DateTime.now());
    _date = widget.initialValue;
    _controller.text = widget.initialValue == null
        ? ''
        : _setting.dateFormat(widget.initialValue ?? DateTime(9999));

    super.initState();
  }

  @pragma('vm:entry-point')
  static Route<DateTime> _datePickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return DatePickerDialog(
          initialDate: DateTime.fromMillisecondsSinceEpoch(arguments! as int),
          restorationId: 'date_picker_dialog',
          initialEntryMode: DatePickerEntryMode.calendarOnly,
          firstDate: DateTime(2022),
          lastDate: DateTime(9999),
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
    if (widget.onChanged != null) {
      widget.onChanged!(newSelectedDate);
    }
    if (newSelectedDate != null) {
      setState(() {
        _selectedDate.value = newSelectedDate;
        _date = newSelectedDate;
        _controller.text = _setting.dateFormat(newSelectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Stack(children: [
          TextFormField(
            onTap: () {
              _restorableDatePickerRouteFuture.present();
            },
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

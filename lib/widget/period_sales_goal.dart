import 'package:fe_pos/model/sales_transaction_report.dart';
import 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/tool/text_formatter.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:flutter/material.dart';

enum Period {
  week,
  day,
  month,
  year;

  String humanize() {
    switch (this) {
      case week:
        return 'Mingguan';
      case day:
        return 'Harian';
      case month:
        return 'Mingguan';
      case year:
        return 'Tahunan';
      default:
        return '';
    }
  }
}

class PeriodSalesGoal extends StatelessWidget with TextFormatter {
  final Money totalSales;
  final Money expectedSales;
  final Period period;
  final List<SalesTransactionReport> salesTransactionReports;
  const PeriodSalesGoal(
      {super.key,
      required this.totalSales,
      required this.period,
      required this.expectedSales,
      required this.salesTransactionReports});

  Date get startDate {
    final today = Date.today();
    switch (period) {
      case Period.year:
        return today.beginningOfYear();
      case Period.month:
        return today.beginningOfMonth();
      case Period.week:
        return today.beginningOfWeek();
      case Period.day:
        return today;
      default:
        throw "not supported";
    }
  }

  Date get endDate {
    final today = Date.today();
    switch (period) {
      case Period.year:
        return today.endOfYear();
      case Period.month:
        return today.endOfMonth();
      case Period.week:
        return today.endOfWeek();
      case Period.day:
        return today;
      default:
        throw "not supported";
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Column(
        children: [
          const Text(
            'Target',
          ),
          Text(
            period.humanize(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      title: Align(
          alignment: Alignment.centerRight,
          child: Text("Total Sales: ${totalSales.format(decimalDigits: 0)}")),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text("Target Penjualan ${expectedSales.format(decimalDigits: 0)}"),
          Text(
            "periode ${startDate.format()} - ${endDate.format()}",
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
      // trailing: ElevatedButton(onPressed: () {}, child: const Text('Detail')),
    );
  }
}

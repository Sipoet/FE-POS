import 'package:fe_pos/components/dropdown_remote_menu.dart';
import 'package:flutter/material.dart';

class SalesPercentageReportPage extends StatelessWidget {
  const SalesPercentageReportPage({super.key});
  @override
  Widget build(BuildContext context) {
    Server server = Server(host: 'localhost', port: 3000, jwt: '', session: '');
    return Center(
      child: Column(
        children: [
          const Text('Filter'),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Merek :'),
                const SizedBox(width: 10),
                DropdownRemoteMenu(
                    path: '/brands', server: server, initialSelection: '')
              ],
            ),
          ),
        ],
      ),
    );
  }
}

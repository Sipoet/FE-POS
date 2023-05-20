import 'package:flutter/material.dart';
import 'package:kasir_frontend/pages/home.dart';
import 'package:kasir_frontend/pages/loading.dart';
import 'package:kasir_frontend/pages/report.dart';

void main() {
  runApp(MaterialApp(initialRoute: '/', routes: {
    // '/': (context) => const Loading(),
    '/': (context) => const Home(),
    '/home': (context) => const Home(),
    '/report': (context) => const Report(),
  }));
}

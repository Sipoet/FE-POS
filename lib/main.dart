import 'package:flutter/material.dart';
import 'package:fe_pos/pages/home.dart';
import 'package:fe_pos/pages/loading.dart';
import 'package:fe_pos/pages/report.dart';

void main() {
  runApp(MaterialApp(initialRoute: '/', routes: {
    // '/': (context) => const Loading(),
    '/': (context) => const Home(),
    '/home': (context) => const Home(),
    '/report': (context) => const Report(),
  }));
}
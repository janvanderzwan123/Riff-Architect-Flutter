import 'package:flutter/material.dart';
import 'package:riff_architect/pages/dashboard_page.dart';

void main() {
  runApp(const RiffArchitectApp());
}

class RiffArchitectApp extends StatelessWidget {
  const RiffArchitectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riff Architect',
      theme: ThemeData.dark(useMaterial3: true),
      home: const DashboardPage(),
    );
  }
}

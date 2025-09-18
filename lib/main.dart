import 'package:flutter/material.dart';
import 'package:logger_boy/screens/log_list_screen.dart';

void main() {
  runApp(const WorkLogApp());
}

class WorkLogApp extends StatelessWidget {
  const WorkLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Log',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LogListScreen(),
    );
  }
}

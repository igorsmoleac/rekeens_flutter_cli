import 'package:flutter/material.dart';

class {{class_name}}Screen extends StatelessWidget {
  const {{class_name}}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{class_name}}')),
      body: const Center(child: Text('{{class_name}} Screen')),
    );
  }
}

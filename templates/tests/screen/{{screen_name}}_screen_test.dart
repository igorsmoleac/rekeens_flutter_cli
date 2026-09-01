import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/features/{{feature_name}}/presentation/pages/{{screen_name}}_screen.dart';

void main() {
  group('{{class_name}}Screen', () {
    testWidgets('renders AppBar with expected title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: {{class_name}}Screen()),
      );

      expect(find.text('{{class_name}}'), findsOneWidget);
    });

    testWidgets('renders screen body text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: {{class_name}}Screen()),
      );

      expect(find.text('{{class_name}} Screen'), findsOneWidget);
    });
  });
}

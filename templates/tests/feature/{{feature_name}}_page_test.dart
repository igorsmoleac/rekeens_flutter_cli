import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/features/{{feature_name}}/presentation/pages/{{feature_name}}_page.dart';

void main() {
  group('{{class_name}}Page', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: {{class_name}}Page()),
      );

      expect(find.byType({{class_name}}Page), findsOneWidget);
    });
  });
}

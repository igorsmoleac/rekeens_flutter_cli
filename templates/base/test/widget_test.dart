import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/app/app.dart';

void main() {
  testWidgets('App renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Welcome to {{project_name}}'), findsOneWidget);
  });
}

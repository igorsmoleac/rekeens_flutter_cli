import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app/app.dart';

void main() {
  testWidgets('App renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Welcome to my_app'), findsOneWidget);
  });
}

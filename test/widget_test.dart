import 'package:flutter_test/flutter_test.dart';
import 'package:logika_kids_app/main.dart';

void main() {
  testWidgets('Logika Kids app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LogikaKidsApp());
    expect(find.byType(LogikaKidsApp), findsOneWidget);
  });
}

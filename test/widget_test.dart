import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printa/main.dart';

void main() {
  testWidgets('PrintaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PrintaApp(),
      ),
    );
    expect(find.byType(PrintaApp), findsOneWidget);
  });
}

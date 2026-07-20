import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printa/main.dart';

void main() {
  testWidgets('SunmiApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SunmiApp(),
      ),
    );
    expect(find.byType(SunmiApp), findsOneWidget);
  });
}

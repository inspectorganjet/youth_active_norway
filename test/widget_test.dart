import 'package:flutter_test/flutter_test.dart';
import 'package:youth_active_norway/main.dart';

void main() {
  testWidgets('App launch smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UngdomsAktivitetApp());
    expect(find.byType(UngdomsAktivitetApp), findsOneWidget);
  });
}

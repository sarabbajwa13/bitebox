// Basic smoke test for the BiteBox client app.
import 'package:flutter_test/flutter_test.dart';

import 'package:bitebox/main.dart';

void main() {
  testWidgets('App boots and shows the brand name', (tester) async {
    await tester.pumpWidget(const BiteBoxApp());
    await tester.pump();

    // Brand name appears in the header.
    expect(find.text('BiteBox'), findsWidgets);
  });
}

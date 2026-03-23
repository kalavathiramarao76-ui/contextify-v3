import 'package:flutter_test/flutter_test.dart';

import 'package:contextify_mobile/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ContextifyApp());
    expect(find.text('Contextify'), findsWidgets);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kin/app/app.dart';

void main() {
  testWidgets('missing config cannot imply a connected product', (
    tester,
  ) async {
    await tester.pumpWidget(const KinApp(configured: false));
    expect(find.text('Connect your project'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
    expect(
      find.textContaining('No account or AI service is connected yet'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

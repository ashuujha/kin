import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kin/app/app.dart';

void main() {
  testWidgets('missing config cannot imply a connected product', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const KinApp(configured: false));
    await tester.scrollUntilVisible(find.text('Service not connected'), 250);
    expect(find.text('Service not connected'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.textContaining('Install the configured build'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kin/app/theme.dart';
import 'package:kin/core/kin_repository.dart';
import 'package:kin/features/prescriptions/home_screen.dart';
import 'package:kin/features/emergency/medical_screen.dart';

class FictionalRepository extends KinRepository {
  FictionalRepository()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'fictional',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  @override
  Future<List<RecordMap>> documents() async => [];
  @override
  Future<List<RecordMap>> labs() async => [];
  @override
  Future<RecordMap?> summary() async => {
    'display_name': 'FICTIONAL Example',
    'medicines': [],
    'allergies': [],
    'notes': '',
  };
  @override
  Future<String?> emergencyLink() async => null;
}

void main() {
  testWidgets(
    'small phone uses a scrollable side drawer, no bottom navigation',
    (t) async {
      t.view.physicalSize = const Size(320, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        MaterialApp(
          theme: kinTheme(),
          home: HomeScreen(repository: FictionalRepository()),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      await t.tap(find.byTooltip('Open navigation menu'));
      await t.pumpAndSettle();
      expect(find.text('Drive & linked files'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('public medical QR requires explicit consent before publishing', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        theme: kinTheme(),
        home: MedicalScreen(repository: FictionalRepository()),
      ),
    );
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Publish emergency QR'), 250);
    final button = find.widgetWithText(FilledButton, 'Publish emergency QR');
    expect(t.widget<FilledButton>(button).onPressed, isNull);
    await t.ensureVisible(find.byType(CheckboxListTile));
    await t.tap(find.byType(CheckboxListTile));
    await t.pump();
    expect(t.widget<FilledButton>(button).onPressed, isNotNull);
    expect(t.takeException(), isNull);
  });
}

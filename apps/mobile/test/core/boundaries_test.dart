import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kin/core/kin_repository.dart';
import 'package:kin/features/prescriptions/date_range.dart';

void main() {
  test('last month crosses January and leap-year boundaries', () {
    final january = calendarMonth(DateTime(2026, 1, 9), previous: true);
    expect(january.from, DateTime(2025, 12, 1));
    expect(january.to, DateTime(2025, 12, 31));
    final leap = calendarMonth(DateTime(2024, 3, 1), previous: true);
    expect(leap.to, DateTime(2024, 2, 29));
  });
  test('each bearer token is 256-bit URL-safe randomness and hashes before storage', () {
    final tokens = List.generate(100, (_) => newToken());
    expect(tokens.toSet().length, 100);
    expect(
      tokens.every((v) => RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(v)),
      isTrue,
    );
    expect(
      tokenHash('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
  test('file limits and signature checks reject unsupported uploads', () {
    expect(
      imageMime(Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10])),
      'image/png',
    );
    expect(imageMime(Uint8List.fromList('not an image'.codeUnits)), isNull);
    expect(imageMime(Uint8List(5242881)), isNull);
  });
}

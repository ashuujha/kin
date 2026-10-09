import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kin/core/report_source.dart';

void main() {
  test('direct report URLs reject executable, credential, local and nonstandard-port sources', () {
    for (final s in [
      'http://example.com/a.pdf',
      'javascript:alert(1)',
      'https://user:password@example.com/a.pdf',
      'https://localhost/a.pdf',
      'https://lab.local/a.pdf',
      'https://example.com:8443/a.pdf',
    ]) {
      expect(() => reportUri(s), throwsFormatException);
    }
    expect(
      reportUri('https://example.com/report.pdf?download=1').host,
      'example.com',
    );
  });
  test('report source resolution excludes private and loopback addresses', () {
    for (final s in [
      '127.0.0.1',
      '10.0.0.2',
      '192.168.1.2',
      '172.16.0.1',
      '169.254.169.254',
      '::1',
      'fc00::1',
      '::ffff:127.0.0.1',
    ]) {
      expect(publicReportAddress(InternetAddress(s)), isFalse);
    }
    expect(publicReportAddress(InternetAddress('8.8.8.8')), isTrue);
  });
}

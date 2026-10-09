import 'package:flutter_test/flutter_test.dart';
import 'package:kin/core/extraction_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'missing AI configuration offers manual review without a retry loop',
    () {
      final message = extractionFailureMessage(
        const FunctionException(
          status: 503,
          details: {
            'error': 'AI is not configured. You can enter fields manually.',
          },
        ),
      );
      expect(message, contains('AI is not configured'));
      expect(message, contains('manually'));
      expect(message.toLowerCase(), isNot(contains('retry')));
    },
  );

  test('unexpected errors do not expose service payloads or claim no save', () {
    const sensitive = 'private-medical-data-and-provider-key';
    for (final failure in [
      const FunctionException(status: 502, details: {'error': sensitive}),
      const FunctionException(status: 503, details: sensitive),
      Exception(sensitive),
    ]) {
      final message = extractionFailureMessage(failure);
      expect(message, isNot(contains(sensitive)));
      expect(message, contains('check for a saved draft'));
      expect(message, isNot(contains('No AI result was saved')));
    }
  });
}

import 'package:supabase_flutter/supabase_flutter.dart';

String extractionFailureMessage(Object failure) {
  if (failure is FunctionException) {
    final details = failure.details;
    if (failure.status == 503 &&
        details is Map &&
        details['error'] ==
            'AI is not configured. You can enter fields manually.') {
      return 'AI is not configured for this build. Enter the fields manually, '
          'compare them with the image, and save your reviewed record.';
    }
    if (failure.status == 401) {
      return 'Your session could not be verified. Sign in again before '
          'requesting extraction.';
    }
    if (failure.status == 429) {
      return 'Too many extraction requests. Wait before retrying, or enter '
          'the fields manually.';
    }
  }
  // Never render arbitrary service details, which may contain sensitive data.
  // A lost response cannot establish whether the server saved a draft.
  return 'AI extraction could not complete. Reopen the record to check for '
      'a saved draft, or enter the fields manually.';
}

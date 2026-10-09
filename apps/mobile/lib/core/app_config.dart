import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const recipientUrl = String.fromEnvironment('RECIPIENT_URL');
  static const _localAuth = bool.fromEnvironment('ALLOW_LOCAL_AUTH');
  static bool get localAuth => !kReleaseMode && _localAuth;
  static bool get configured {
    final database = Uri.tryParse(supabaseUrl);
    final receiver = Uri.tryParse(recipientUrl);
    if (supabaseKey.isEmpty ||
        database == null ||
        receiver == null ||
        database.host.isEmpty ||
        receiver.host.isEmpty) {
      return false;
    }
    return !kReleaseMode ||
        (database.scheme == 'https' && receiver.scheme == 'https');
  }
}

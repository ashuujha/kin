import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/app_config.dart';
import 'core/session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var ready = false;
  if (AppConfig.configured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseKey,
        debug: false,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          localStorage: SecureSessionStorage(),
          pkceAsyncStorage: SecurePkceStorage(),
          detectSessionInUriPredicate: (uri) =>
              uri.scheme == 'dev.ashuujha.kin' &&
              uri.host == 'auth' &&
              uri.path == '/callback',
        ),
      );
      ready = true;
    } catch (_) {
      /* Configuration failures are displayed without exposing credentials. */
    }
  }
  runApp(KinApp(configured: ready));
}

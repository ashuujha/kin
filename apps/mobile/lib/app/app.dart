import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/auth_screen.dart';
import '../features/prescriptions/home_screen.dart';
import '../core/kin_repository.dart';
import 'theme.dart';

class KinApp extends StatefulWidget {
  const KinApp({super.key, required this.configured});
  final bool configured;
  @override
  State<KinApp> createState() => _KinAppState();
}

class _KinAppState extends State<KinApp> {
  final navigator = GlobalKey<NavigatorState>();
  final messenger = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<AuthState>? subscription;
  @override
  void initState() {
    super.initState();
    if (widget.configured) {
      subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
        (event) {
          if (event.session == null) {
            navigator.currentState?.popUntil((r) => r.isFirst);
            PaintingBinding.instance.imageCache.clear();
            PaintingBinding.instance.imageCache.clearLiveImages();
          }
          if (mounted) setState(() {});
        },
        onError: (Object _) {
          messenger.currentState?.showSnackBar(
            const SnackBar(
              content: Text(
                'Google sign-in could not complete. Please try again.',
              ),
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.configured ? Supabase.instance.client : null;
    return MaterialApp(
      title: 'Kin',
      debugShowCheckedModeBanner: false,
      theme: kinTheme(),
      navigatorKey: navigator,
      scaffoldMessengerKey: messenger,
      home: client?.auth.currentUser == null
          ? AuthScreen(configured: widget.configured)
          : HomeScreen(
              key: ValueKey(client!.auth.currentUser!.id),
              repository: KinRepository(client),
            ),
    );
  }
}

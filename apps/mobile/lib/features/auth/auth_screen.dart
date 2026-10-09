import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';
import '../../core/widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.configured});
  final bool configured;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool busy = false;
  Future<void> login() async {
    setState(() => busy = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'dev.ashuujha.kin://auth/callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
        queryParams: {'prompt': 'select_account'},
      );
    } catch (_) {
      if (mounted) {
        showNotice(context, 'Could not open Google sign-in. Try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> localLogin() async {
    final email = TextEditingController();
    final password = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Local test account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Development only. This does not test Google OAuth.'),
            const SizedBox(height: 16),
            TextField(
              controller: email,
              decoration: const InputDecoration(
                labelText: 'Fictional test email',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Local password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      } catch (_) {
        if (mounted) showNotice(context, 'Local test sign-in failed.');
      }
    }
    email.dispose();
    password.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 24),
          const Text(
            'kin',
            style: TextStyle(
              fontSize: 54,
              fontWeight: FontWeight.w700,
              letterSpacing: -3,
            ),
          ),
          const SizedBox(height: 64),
          Text(
            'Care begins\nwith context.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 24),
          const Text(
            'Your prescriptions, reviewed by you. Your summary, shared with permission.',
            style: TextStyle(fontSize: 18, height: 1.5),
          ),
          const SizedBox(height: 28),
          const KinCard(
            title: 'A little context. Better care.',
            icon: Icons.favorite_outline,
            child: Text(
              'Keep original records private. Choose what to share. Your family opens the summary in a browser — no app needed.',
            ),
          ),
          const SizedBox(height: 24),
          if (widget.configured)
            BusyButton(
              busy: busy,
              label: 'Continue with Google',
              onPressed: login,
            )
          else
            const KinCard(
              title: 'Connect your project',
              child: Text(
                'Build with SUPABASE_URL, SUPABASE_ANON_KEY and RECIPIENT_URL. The setup guide is in the repository. No account or AI service is connected yet.',
              ),
            ),
          if (widget.configured && AppConfig.localAuth)
            TextButton(
              onPressed: localLogin,
              child: const Text('Local testing · password account'),
            ),
          const SizedBox(height: 24),
          const Text(
            'Hackathon prototype · fictional records only\nOwner review is not clinical verification.',
            style: TextStyle(fontSize: 12, color: Color(0xff5c7064)),
          ),
        ],
      ),
    ),
  );
}

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
      final opened = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'dev.ashuujha.kin://auth/callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
        queryParams: {'prompt': 'select_account'},
      );
      if (!opened && mounted) {
        showNotice(context, 'Google sign-in could not open. Please try again.');
      }
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

  void privacy() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(28, 8, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your information. Your permission.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 20),
            Text(
              'Google sign-in identifies your account. Kin requests your basic profile and email; it does not request access to Google Drive or Gmail.',
            ),
            SizedBox(height: 16),
            Text(
              'Your prescription images and history are private to your account. If you request AI extraction, the server sends that image to the configured AI provider. Review every extracted field before saving.',
            ),
            SizedBox(height: 16),
            Text(
              'A medical invitation shares only your published selection with one Google account for 24 hours. A separate contact QR makes the contacts you choose public to anyone with that link.',
            ),
            SizedBox(height: 16),
            Text(
              'You can delete prescriptions and revoke links. Revocation cannot erase information someone already copied. Kin does not provide diagnosis or treatment recommendations.',
            ),
            SizedBox(height: 20),
            Text(
              'Use fictional records for the hackathon. Server and AI processing are not end-to-end encrypted.',
              style: TextStyle(fontSize: 12, color: Color(0xff65766b)),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
            children: [
              const Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 18,
                runSpacing: 12,
                children: [
                  KinBrand(),
                  KinBadge('PRIVATE BY CHOICE', icon: Icons.lock_outline),
                ],
              ),
              const SizedBox(height: 44),
              Text(
                'Care begins\nwith context.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your records in one place. The right information, shared with the people you choose.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xff65766b),
                ),
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xff173d33),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        KinBadge(
                          'YOUR CARE RECORD',
                          dark: true,
                          icon: Icons.favorite_outline,
                        ),
                        Icon(
                          Icons.shield_outlined,
                          color: Color(0xffd4e5d3),
                          size: 26,
                        ),
                      ],
                    ),
                    SizedBox(height: 28),
                    Text(
                      'Keep the original.\nShare the essentials.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.6,
                      ),
                    ),
                    SizedBox(height: 22),
                    Divider(color: Color(0xff466456)),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: Color(0xffd4e5d3),
                          size: 19,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Prescriptions · Reviewed summaries · Contacts',
                            style: TextStyle(
                              color: Color(0xffd4e5d3),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              if (widget.configured)
                FilledButton(
                  onPressed: busy
                      ? null
                      : AppConfig.localAuth
                      ? localLogin
                      : login,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!AppConfig.localAuth) ...[
                              const Icon(
                                Icons.account_circle_outlined,
                                size: 21,
                              ),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              AppConfig.localAuth
                                  ? 'Sign in to local test build'
                                  : 'Continue with Google',
                            ),
                          ],
                        ),
                )
              else
                const KinCard(
                  title: 'Service not connected',
                  child: Text(
                    'Sign-in will be available when the service is connected. Install the configured build to continue.',
                  ),
                ),
              if (widget.configured && !AppConfig.localAuth) ...[
                const SizedBox(height: 12),
                const Text(
                  'New here? Your first sign-in creates your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xff65766b)),
                ),
              ],
              if (widget.configured && AppConfig.localAuth)
                const KinCard(
                  title: 'Local testing · fictional account',
                  child: Text(
                    'Use the test account created on your laptop. Password login does not demonstrate Google OAuth.',
                  ),
                ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: privacy,
                child: const Text('How Kin uses your information'),
              ),
              const Text(
                'Record information, not medical advice.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xff65766b)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

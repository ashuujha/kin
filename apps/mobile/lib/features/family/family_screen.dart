import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/kin_repository.dart';
import '../../core/widgets.dart';
import '../../core/link_sheet.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key, required this.repository});
  final KinRepository repository;
  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final email = TextEditingController();
  late Future<List<RecordMap>> invites;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    invites = widget.repository.shares();
  }

  void refresh() {
    if (mounted) setState(() => invites = widget.repository.shares());
  }

  Future<void> create() async {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.text.trim())) {
      showNotice(context, 'Enter the recipient’s Google account email.');
      return;
    }
    setState(() => busy = true);
    try {
      final summary = await widget.repository.summary();
      if (summary == null) {
        if (mounted) showNotice(context, 'Publish a selected summary first.');
        return;
      }
      final share = await widget.repository.share(email.text.trim());
      if (mounted) {
        await showLink(
          context,
          title: '24-hour medical invitation',
          url: share['url'],
          explanation:
              'Only ${email.text.trim()} can accept this link using Google. Expires ${DateFormat.yMMMd().add_jm().format(DateTime.parse(share['expires_at']).toLocal())}. The recipient needs a browser and internet.',
        );
      }
    } catch (error) {
      if (mounted) showNotice(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => busy = false);
      refresh();
    }
  }

  Future<void> revoke(String id) async {
    try {
      await widget.repository.revoke(id);
      refresh();
    } catch (error) {
      if (mounted) showNotice(context, friendlyError(error));
    }
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Family access')),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const KinCard(
          title: 'Chosen people. Chosen information.',
          icon: Icons.people_outline,
          child: Text(
            'An invitation captures your published summary. It expires 24 hours after creation. The recipient must sign in with the Google email you enter. Google does not verify family relationships.',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          maxLength: 254,
          decoration: const InputDecoration(
            labelText: 'Recipient’s Google email',
          ),
        ),
        BusyButton(busy: busy, label: 'Create invitation', onPressed: create),
        const SizedBox(height: 16),
        const Text(
          'The link is shown once. Use Copy or Share before closing it. To replace a lost link, revoke it and create another.',
        ),
        const SizedBox(height: 20),
        FutureBuilder<List<RecordMap>>(
          future: invites,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return TextButton(
                onPressed: refresh,
                child: const Text('Could not load invitations · retry'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.isEmpty) {
              return const KinCard(
                title: 'No invitations yet',
                child: Text(
                  'Publish a summary, then invite someone you trust.',
                ),
              );
            }
            return Column(
              children: snapshot.data!.map((share) {
                final expired = DateTime.parse(share['expires_at'])
                    .isBefore(DateTime.now());
                final revoked = share['revoked_at'] != null;
                return KinCard(
                  title: share['recipient_email'],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        revoked
                            ? 'Revoked'
                            : expired
                            ? 'Expired'
                            : share['accepted_at'] != null
                            ? 'Accepted · view only'
                            : 'Pending acceptance',
                      ),
                      Text(
                        'Expires ${DateFormat.yMMMd().add_jm().format(DateTime.parse(share['expires_at']).toLocal())}',
                      ),
                      if (!revoked && !expired)
                        TextButton(
                          onPressed: () => revoke(share['id']),
                          child: const Text('Revoke access'),
                        ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Revocation stops future requests. It cannot erase screenshots or information already copied.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

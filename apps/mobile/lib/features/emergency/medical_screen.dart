import 'package:flutter/material.dart';

import '../../core/kin_repository.dart';
import '../../core/widgets.dart';
import '../../core/link_sheet.dart';
import '../summary/summary_screen.dart';

class MedicalScreen extends StatefulWidget {
  const MedicalScreen({super.key, required this.repository});
  final KinRepository repository;
  @override
  State<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends State<MedicalScreen> {
  bool loading = true, busy = false, consent = false, failed = false;
  String? link;
  List<RecordMap> labs = [];
  final selected = <String>{};
  RecordMap? summary;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final s = await widget.repository.summary();
      final l = await widget.repository.labs();
      final url = await widget.repository.emergencyLink();
      if (mounted) {
        setState(() {
          summary = s;
          labs = l.where((r) => r['status'] == 'reviewed').toList();
          link = url;
          loading = false;
          failed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          failed = true;
        });
      }
    }
  }

  Future<void> publish() async {
    if (!consent || summary == null) return;
    setState(() => busy = true);
    try {
      final url = await widget.repository.publishEmergency(selected.toList());
      if (mounted) {
        setState(() => link = url);
        await showLink(
          context,
          title: 'Emergency medical QR',
          url: url,
          explanation: 'Anyone holding this QR can read your selected medical summary and selected reviewed lab results. No sign-in is required. Originals and Drive links stay private. This snapshot stays active until revoked or replaced.',
        );
      }
    } catch (_) {
      if (mounted) {
        showNotice(
          context,
          'Emergency QR could not publish. Save a selected summary first.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> revoke() async {
    try {
      await widget.repository.revokeEmergency();
      if (mounted) setState(() => link = null);
    } catch (_) {
      if (mounted) showNotice(context, 'Could not revoke. Retry.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Emergency medical access')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : failed
        ? Center(
            child: TextButton(
              onPressed: load,
              child: const Text('Could not load · retry'),
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Critical context. No login.',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'A doctor or first responder can scan this separate QR and read the selected medical snapshot in a browser. Kin cannot verify that the person scanning is a doctor.',
                style: TextStyle(color: Color(0xff707079)),
              ),
              const SizedBox(height: 18),
              KinCard(
                title: 'The selection you will publish',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary?['display_name'] ?? 'No selected summary yet'),
                    const SizedBox(height: 8),
                    Text(
                      '${(summary?['medicines'] as List?)?.length ?? 0} selected medicines · ${(summary?['allergies'] as List?)?.length ?? 0} allergy entries',
                    ),
                    if (summary?['notes'] != null &&
                        summary!['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(summary!['notes']),
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                SummaryScreen(repository: widget.repository),
                          ),
                        );
                        await load();
                      },
                      child: const Text('Edit your selected summary'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Include reviewed laboratory results',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (labs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Review a lab report first to include its results.',
                    style: TextStyle(color: Color(0xff707079)),
                  ),
                ),
              ...labs.map(
                (r) => CheckboxListTile(
                  value: selected.contains(r['id']),
                  title: Text(r['title']),
                  subtitle: Text(r['report_date'] ?? 'Date not recorded'),
                  onChanged: busy
                      ? null
                      : (v) => setState(() {
                          if (v == true) {
                            if (selected.length < 10) selected.add(r['id']);
                          } else {
                            selected.remove(r['id']);
                          }
                        }),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: consent,
                onChanged: busy
                    ? null
                    : (v) => setState(() => consent = v ?? false),
                title: const Text(
                  'I allow anyone with this QR to read this selected medical information without signing in.',
                ),
                subtitle: const Text(
                  'This includes people who photograph or forward the QR. Copied information cannot be recalled.',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy || !consent || summary == null ? null : publish,
                child: Text(busy ? 'Publishing…' : 'Publish emergency QR'),
              ),
              if (link != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => showLink(
                    context,
                    title: 'Emergency medical QR',
                    url: link!,
                    explanation: 'Selected medical snapshot · no sign-in · internet required. Anyone with this QR can read it.',
                  ),
                  child: const Text('Show current emergency QR'),
                ),
                TextButton(
                  onPressed: busy ? null : revoke,
                  child: const Text('Revoke emergency medical access'),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Publishing replaces the previous QR. Changes to your source records do not update this snapshot: publish again to share a new selection. Deleting a source record revokes the emergency QR. Print the QR somewhere accessible; Kin cannot unlock a phone.',
                style: TextStyle(fontSize: 12, color: Color(0xff707079)),
              ),
            ],
          ),
  );
}

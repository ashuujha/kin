import 'package:flutter/material.dart';

import '../../core/kin_repository.dart';
import '../../core/widgets.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, required this.repository});
  final KinRepository repository;
  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      allergies = TextEditingController(),
      notes = TextEditingController();
  List<RecordMap> medications = [];
  final selected = <String>{};
  bool loading = true, busy = false, failed = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final summary = await widget.repository.summary();
      final records = await widget.repository.search();
      if (mounted) {
        setState(() {
          name.text = summary?['display_name'] ?? '';
          allergies.text = List<String>.from(summary?['allergies'] ?? [])
              .join('\n');
          notes.text = summary?['notes'] ?? '';
          medications = List<RecordMap>.from(records['matches']);
          loading = false;
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
    if (!form.currentState!.validate()) return;
    final entries = allergies.text
        .split('\n')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    if (entries.length > 30 || entries.any((v) => v.length > 200)) {
      showNotice(
        context,
        'Use at most 30 allergy entries of up to 200 characters.',
      );
      return;
    }
    setState(() => busy = true);
    try {
      await widget.repository.publish(
        name.text.trim(),
        entries,
        notes.text.trim(),
        selected.toList(),
      );
      if (mounted) {
        showNotice(
          context,
          'Summary published. New invitations will use this selection.',
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) showNotice(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    allergies.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose your summary')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : failed
        ? Center(
            child: TextButton(
              onPressed: load,
              child: const Text('Could not load · retry'),
            ),
          )
        : Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                const Text(
                  'Choose exactly what a recipient can read. Original files and your full history remain private.',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: name,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Your displayed name',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Name is required.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: allergies,
                  minLines: 2,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Owner-reported allergies',
                    helperText: 'One entry per line. Empty means not recorded.',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select reviewed medicines',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Saving replaces the published medicine selection. Re-select the entries you want included. Existing invitation snapshots stay unchanged.',
                ),
                if (medications.isEmpty)
                  const KinCard(
                    title: 'No reviewed medicines yet',
                    child: Text(
                      'Review a prescription to include its medicines. You can still publish owner-reported allergies and notes.',
                    ),
                  ),
                ...medications.map(
                  (m) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selected.contains(m['id']),
                    onChanged: busy
                        ? null
                        : (v) => setState(() {
                            if (v == true) {
                              if (selected.length < 30) selected.add(m['id']);
                            } else {
                              selected.remove(m['id']);
                            }
                          }),
                    title: Text(m['name']),
                    subtitle: Text(
                      '${m['prescription_date'] ?? 'Date unknown'} · ${m['dosage'] ?? 'Dosage unknown'}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notes,
                  maxLength: 1000,
                  minLines: 2,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Notes you choose to share',
                  ),
                ),
                const SizedBox(height: 20),
                BusyButton(
                  busy: busy,
                  label: 'Publish selected summary',
                  onPressed: publish,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Owner review is not clinical verification. Prescription entries do not establish adherence.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
  );
}

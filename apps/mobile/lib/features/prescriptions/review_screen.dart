import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/extraction_error.dart';
import '../../core/kin_repository.dart';
import '../../core/widgets.dart';

class MedicineEditor {
  MedicineEditor(RecordMap value)
    : name = TextEditingController(text: value['name']),
      dosage = TextEditingController(text: value['dosage']),
      frequency = TextEditingController(text: value['frequency']),
      duration = TextEditingController(text: value['duration']),
      source = value['source_excerpt'],
      status = value['taking_status'] ?? 'unknown';
  final TextEditingController name, dosage, frequency, duration;
  final String? source;
  String status;
  RecordMap get value => {
    'name': name.text.trim(),
    'dosage': dosage.text.trim().isEmpty ? null : dosage.text.trim(),
    'frequency': frequency.text.trim().isEmpty ? null : frequency.text.trim(),
    'duration': duration.text.trim().isEmpty ? null : duration.text.trim(),
    'source_excerpt': source,
    'taking_status': status,
  };
  void dispose() {
    name.dispose();
    dosage.dispose();
    frequency.dispose();
    duration.dispose();
  }
}

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.repository,
    required this.document,
  });
  final KinRepository repository;
  final RecordMap document;
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final form = GlobalKey<FormState>();
  final date = TextEditingController();
  final clinic = TextEditingController();
  final medicines = <MedicineEditor>[];
  Uint8List? bytes;
  bool busy = false, confirmed = false, sourceFailed = false;
  String method = 'Manual entry';
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final file = await widget.repository.original(
        widget.document['object_path'],
      );
      final doc = widget.document;
      final meds = doc['status'] == 'reviewed'
          ? await widget.repository.documentMedications(doc['id'])
          : List<RecordMap>.from(doc['draft']?['medications'] ?? []);
      if (!mounted) return;
      setState(() {
        bytes = file;
        date.text =
            doc['prescription_date'] ??
            doc['draft']?['prescription_date'] ??
            '';
        clinic.text = doc['clinic'] ?? doc['draft']?['clinic'] ?? '';
        method = doc['extraction_method'] == 'gemma'
            ? 'AI extracted · owner review required'
            : 'Manual entry';
        medicines.addAll(meds.map(MedicineEditor.new));
      });
    } catch (_) {
      if (mounted) setState(() => sourceFailed = true);
    }
  }

  void useDraft(RecordMap draft) {
    for (final m in medicines) {
      m.dispose();
    }
    medicines.clear();
    date.text = draft['prescription_date'] ?? '';
    clinic.text = draft['clinic'] ?? '';
    medicines.addAll(
      List<RecordMap>.from(draft['medications']).map(MedicineEditor.new),
    );
  }

  Future<void> extract() async {
    setState(() {
      busy = true;
      error = null;
      confirmed = false;
    });
    try {
      final draft = await widget.repository.extract(widget.document['id']);
      if (mounted) {
        setState(() {
          useDraft(draft);
          method = 'AI extracted · owner review required';
        });
      }
    } catch (failure) {
      if (mounted) {
        setState(() => error = extractionFailureMessage(failure));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!confirmed || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await widget.repository.review(
        widget.document['id'],
        date.text.trim().isEmpty ? null : date.text.trim(),
        clinic.text.trim().isEmpty ? null : clinic.text.trim(),
        medicines.map((m) => m.value).toList(),
      );
      if (mounted) {
        showNotice(
          context,
          'Saved as owner reviewed. Existing shares were revoked; publish and share again.',
        );
        Navigator.pop(context);
      }
    } catch (failure) {
      if (mounted) showNotice(context, friendlyError(failure));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> delete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete prescription?'),
        content: const Text(
          'The original and reviewed entries will be deleted. Published medicines will be cleared and existing shares revoked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => busy = true);
    try {
      await widget.repository.deleteDocument(widget.document);
      if (mounted) Navigator.pop(context);
    } catch (failure) {
      if (mounted) showNotice(context, friendlyError(failure));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    date.dispose();
    clinic.dispose();
    for (final m in medicines) {
      m.dispose();
    }
    bytes = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Review prescription'),
      actions: [
        IconButton(
          tooltip: 'Delete prescription',
          onPressed: busy ? null : delete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text(
            'Compare every field with the image. Keep unclear details empty. Owner review does not establish clinical accuracy.',
          ),
          const SizedBox(height: 20),
          if (bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                bytes!,
                fit: BoxFit.contain,
                gaplessPlayback: false,
              ),
            )
          else if (sourceFailed)
            KinCard(
              title: 'Original could not load',
              child: TextButton(
                onPressed: load,
                child: const Text('Retry loading original'),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          Text(method, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (widget.document['status'] != 'reviewed')
            BusyButton(
              busy: busy,
              label: 'Extract with Gemma',
              onPressed: extract,
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: date,
            decoration: const InputDecoration(
              labelText: 'Prescription date · YYYY-MM-DD',
              helperText:
                  'Leave empty if not stated; never use the upload date.',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final parsed = DateTime.tryParse(v.trim());
              return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v.trim()) &&
                      parsed?.toIso8601String().substring(0, 10) == v.trim()
                  ? null
                  : 'Enter a real date in YYYY-MM-DD format.';
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: clinic,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Clinic · optional'),
          ),
          ...medicines.asMap().entries.map((entry) {
            final m = entry.value;
            return KinCard(
              title: 'Medicine ${entry.key + 1}',
              child: Column(
                children: [
                  TextFormField(
                    controller: m.name,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      labelText: 'Medicine name as written',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: m.dosage,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Dosage · optional',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: m.frequency,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Frequency · optional',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: m.duration,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Duration as written · optional',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: m.status,
                    decoration: const InputDecoration(
                      labelText: 'Your reported use',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'unknown',
                        child: Text('Not confirmed'),
                      ),
                      DropdownMenuItem(
                        value: 'taking',
                        child: Text('I report taking this'),
                      ),
                      DropdownMenuItem(
                        value: 'stopped',
                        child: Text('I report having stopped'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) m.status = v;
                    },
                  ),
                  if (m.source != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text('Extracted source text: ${m.source}'),
                    ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            medicines.removeAt(entry.key);
                            m.dispose();
                          }),
                    child: const Text('Remove medicine'),
                  ),
                ],
              ),
            );
          }),
          if (medicines.length < 30)
            TextButton.icon(
              onPressed: busy
                  ? null
                  : () => setState(() => medicines.add(MedicineEditor({}))),
              icon: const Icon(Icons.add),
              label: const Text('Add a medicine manually'),
            ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: confirmed,
            onChanged: bytes == null || busy
                ? null
                : (v) => setState(() => confirmed = v ?? false),
            title: const Text('I compared these fields with the prescription.'),
            subtitle: const Text(
              'Prescribed duration does not prove current use.',
            ),
          ),
          FilledButton(
            onPressed: !confirmed || busy ? null : save,
            child: Text(busy ? 'Saving…' : 'Save reviewed record'),
          ),
          const SizedBox(height: 28),
        ],
      ),
    ),
  );
}

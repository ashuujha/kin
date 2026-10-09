import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/kin_repository.dart';
import '../../core/widgets.dart';

class LinkedScreen extends StatefulWidget {
  const LinkedScreen({super.key, required this.repository});
  final KinRepository repository;
  @override
  State<LinkedScreen> createState() => _LinkedScreenState();
}

class _LinkedScreenState extends State<LinkedScreen> {
  late Future<List<RecordMap>> rows;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    rows = widget.repository.linkedReports();
  }

  void refresh() => setState(() => rows = widget.repository.linkedReports());
  Future<void> add() async {
    final title = TextEditingController(), url = TextEditingController();
    String kind = 'drive';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Link an external report'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  maxLength: 160,
                  decoration: const InputDecoration(labelText: 'Record title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: url,
                  maxLength: 2048,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'HTTPS file or folder link',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: kind,
                  items: const [
                    DropdownMenuItem(
                      value: 'drive',
                      child: Text('Google Drive'),
                    ),
                    DropdownMenuItem(
                      value: 'dicom',
                      child: Text('DICOM / imaging archive'),
                    ),
                    DropdownMenuItem(
                      value: 'lab_portal',
                      child: Text('Laboratory portal'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text('Other external file'),
                    ),
                  ],
                  onChanged: (v) => set(() => kind = v!),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Kin stores the link, not the large file. Access follows the source provider’s permissions. These links stay private and are excluded from emergency QR summaries.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save link'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      try {
        await widget.repository.addLinked(
          title.text.trim(),
          url.text.trim(),
          kind,
        );
        refresh();
      } catch (_) {
        if (mounted) showNotice(context, 'Use a title and a valid HTTPS link.');
      }
    }
    title.dispose();
    url.dispose();
  }

  Future<void> openUrl(String value) async {
    try {
      final uri = Uri.parse(value);
      if (uri.scheme != 'https' ||
          uri.userInfo.isNotEmpty ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception();
      }
    } catch (_) {
      if (mounted) showNotice(context, 'The source could not open.');
    }
  }

  @override
  Widget build(BuildContext _) => Scaffold(
    appBar: AppBar(title: const Text('Drive & linked files')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: add,
      icon: const Icon(Icons.add),
      label: const Text('Add link'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Large originals. Your storage.',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        const Text(
          'Keep DICOM scans, imaging folders and large PDFs in Google Drive. Kin keeps an organized private reference; it does not interpret DICOM images.',
          style: TextStyle(color: Color(0xff707079)),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () =>
              openUrl('https://drive.google.com/drive/u/0/my-drive'),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open your Google Drive'),
        ),
        FutureBuilder<List<RecordMap>>(
          future: rows,
          builder: (ctx, snapshot) {
            if (snapshot.hasError) {
              return TextButton(
                onPressed: refresh,
                child: const Text('Could not load · retry'),
              );
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            if (snapshot.data!.isEmpty) {
              return const KinCard(
                title: 'No linked files',
                child: Text(
                  'Add a Drive file or folder link. Keep the source restricted to the people you choose.',
                ),
              );
            }
            return Column(
              children: snapshot.data!
                  .map(
                    (r) => Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(Icons.folder_open_outlined),
                        title: Text(r['title']),
                        subtitle: Text(
                          '${r['kind']} · ${Uri.tryParse(r['url'])?.host ?? 'External source'}',
                        ),
                        onTap: () => openUrl(r['url']),
                        trailing: IconButton(
                          tooltip: 'Remove saved link',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            try {
                              await widget.repository.deleteLinked(r['id']);
                              if (mounted) refresh();
                            } catch (_) {
                              if (mounted) {
                                showNotice(
                                  context,
                                  'Could not remove the link.',
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 90),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/kin_repository.dart';
import '../../core/widgets.dart';
import '../../core/report_source.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.repository});
  final KinRepository repository;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<RecordMap>> rows;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    rows = widget.repository.labs();
  }

  void refresh() => setState(() => rows = widget.repository.labs());
  Future<void> import() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Lab reports',
          extensions: ['pdf', 'jpg', 'jpeg', 'png'],
          mimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
        ),
      ],
    );
    if (file == null) return;
    if (await file.length() > 5242880) {
      if (mounted) {
        showNotice(
          context,
          'Use a report up to 5 MB. Save larger originals as Drive links.',
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => busy = true);
    try {
      final title = file.name.length > 160
          ? file.name.substring(0, 160)
          : file.name;
      final doc = await widget.repository.uploadLab(
        title,
        await file.readAsBytes(),
      );
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                LabDetailScreen(repository: widget.repository, report: doc),
          ),
        );
      }
      if (mounted) refresh();
    } catch (_) {
      if (mounted) {
        showNotice(
          context,
          'Report could not import. Use a PDF, JPEG or PNG up to 5 MB.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> importLink() async {
    final field = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import a direct report link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: field,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'HTTPS PDF or image URL',
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Use a report file link that downloads without login. Portal pages and restricted Drive files need you to download the file first. Importing sends the report to the AI extraction service.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    final value = field.text.trim();
    field.dispose();
    if (ok != true || !mounted) return;
    setState(() => busy = true);
    try {
      final uri = reportUri(value);
      final bytes = await downloadReport(value);
      final doc = await widget.repository.uploadLab(
        'Report from ${uri.host}',
        bytes,
      );
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                LabDetailScreen(repository: widget.repository, report: doc),
          ),
        );
      }
      if (mounted) refresh();
    } catch (_) {
      if (mounted) {
        showNotice(
          context,
          'This link could not import. Use a direct PDF/image up to 5 MB. For a login or portal page, download the file first.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> portal() async {
    try {
      await launchUrl(
        Uri.parse('https://www.lalpathlabs.com/download-report'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (mounted) showNotice(context, 'Portal could not open.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Laboratory reports')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Results, with their source.',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        const Text(
          'Importing sends the selected report to the AI extraction service. Tests, values, units and source ranges are saved automatically as a private draft. Review before including them in an emergency summary.',
          style: TextStyle(color: Color(0xff707079)),
        ),
        const SizedBox(height: 22),
        BusyButton(
          busy: busy,
          label: 'Import PDF or report image',
          onPressed: import,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy ? null : importLink,
          icon: const Icon(Icons.link),
          label: const Text('Import a direct report link'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: portal,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Get a Dr Lal PathLabs report'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Sign in on the laboratory’s website, download your report, then import it here. Kin does not store portal passwords or bypass its login. Text PDFs: up to 10 pages / 5 MB. For scanned PDFs, import a clear image.',
            style: TextStyle(fontSize: 12, color: Color(0xff707079)),
          ),
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
                title: 'Your report timeline starts here',
                child: Text(
                  'Import a fictional blood report to see extracted results and a source-based summary.',
                ),
              );
            }
            return Column(
              children: snapshot.data!
                  .map(
                    (r) => Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(Icons.biotech_outlined),
                        title: Text(r['title']),
                        subtitle: Text(
                          '${r['report_date'] ?? 'Date not recorded'} · ${r['status']}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => LabDetailScreen(
                                repository: widget.repository,
                                report: r,
                              ),
                            ),
                          );
                          if (mounted) refresh();
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}

class LabDetailScreen extends StatefulWidget {
  const LabDetailScreen({
    super.key,
    required this.repository,
    required this.report,
  });
  final KinRepository repository;
  final RecordMap report;
  @override
  State<LabDetailScreen> createState() => _LabDetailScreenState();
}

class _LabDetailScreenState extends State<LabDetailScreen> {
  late RecordMap report;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    report = {...widget.report};
    if (report['status'] == 'uploaded') Future.microtask(extract);
  }

  Future<void> extract() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = await widget.repository.extractLab(report['id']);
      if (mounted) {
        setState(
          () => report = {
            ...report,
            'draft': data['draft'],
            'summary': data['summary'],
            'status': 'draft',
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Extraction could not complete. Use an unencrypted text PDF or a clearer image; no reviewed result was saved.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> review() async {
    setState(() => busy = true);
    try {
      await widget.repository.reviewLab(report['id']);
      if (mounted) {
        setState(
          () => report = {
            ...report,
            'status': 'reviewed',
            'results': report['draft']['results'],
            'report_date': report['draft']['report_date'],
            'laboratory': report['draft']['laboratory'],
          },
        );
        showNotice(
          context,
          'Results reviewed and saved to your report timeline.',
        );
      }
    } catch (_) {
      if (mounted) showNotice(context, 'Could not save reviewed results.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> original() async {
    try {
      final url = await widget.repository.labOriginalUrl(report);
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception();
      }
    } catch (_) {
      if (mounted) showNotice(context, 'Original could not open.');
    }
  }

  Future<void> delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this report?'),
        content: const Text(
          'The original and results will be removed. Your emergency medical QR will be revoked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.repository.deleteLab(report);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) showNotice(context, 'Deletion could not complete. Retry.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = report['draft'] as Map?;
    final results = List<RecordMap>.from(
      report['status'] == 'reviewed'
          ? report['results'] ?? []
          : draft?['results'] ?? [],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report details'),
        actions: [
          IconButton(
            tooltip: 'Delete report',
            onPressed: busy ? null : delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            report['title'],
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${report['status'] == 'reviewed' ? 'Owner reviewed' : 'Unreviewed draft'} · ${report['report_date'] ?? draft?['report_date'] ?? 'Date not recorded'}',
            style: const TextStyle(color: Color(0xff707079)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: original,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open private original'),
          ),
          if (report['status'] != 'reviewed') ...[
            const SizedBox(height: 12),
            BusyButton(
              busy: busy,
              label: results.isEmpty
                  ? 'Extract report details'
                  : 'Re-extract draft',
              onPressed: extract,
            ),
          ],
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error!,
                style: const TextStyle(color: Color(0xffb3261e)),
              ),
            ),
          if (report['summary'] != null)
            KinCard(
              title: 'Source-based summary',
              child: Text(report['summary']),
            ),
          if (results.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Compare every field with the original. Unknown flags are not interpreted as normal.',
              style: TextStyle(fontSize: 12, color: Color(0xff707079)),
            ),
            ...results.map(
              (r) => KinCard(
                title: r['test'],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r['value'] ?? 'Unknown'} ${r['unit'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Source range: ${r['reference_range'] ?? 'Not recorded'}',
                    ),
                    Text('Source flag: ${r['report_flag']}'),
                    if (r['source_excerpt'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        r['source_excerpt'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff707079),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (report['status'] != 'reviewed') ...[
              const SizedBox(height: 20),
              BusyButton(
                busy: busy,
                label: 'I compared the fields · save reviewed results',
                onPressed: review,
              ),
            ],
          ],
          const SizedBox(height: 24),
          const Text(
            'A report summary is information from the source, not a diagnosis or treatment recommendation.',
            style: TextStyle(fontSize: 12, color: Color(0xff707079)),
          ),
        ],
      ),
    );
  }
}

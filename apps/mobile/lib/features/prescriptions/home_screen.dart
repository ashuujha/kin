import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/kin_repository.dart';
import '../../core/widgets.dart';
import '../summary/summary_screen.dart';
import '../family/family_screen.dart';
import '../emergency/contact_screen.dart';
import 'review_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});
  final KinRepository repository;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<RecordMap>> records;
  bool uploading = false;
  @override
  void initState() {
    super.initState();
    records = widget.repository.documents();
  }

  Future<void> refresh() async {
    if (mounted) setState(() => records = widget.repository.documents());
  }

  Future<void> open(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    await refresh();
  }

  Future<void> upload() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Choose prescription image'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    if (mounted) setState(() => uploading = true);
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (imageMime(bytes) == null) {
        if (mounted) {
          showNotice(context, 'Use a valid JPEG or PNG image up to 5 MB.');
        }
        return;
      }
      final doc = await widget.repository.upload(bytes);
      if (mounted) {
        await open(ReviewScreen(repository: widget.repository, document: doc));
      }
    } catch (error) {
      if (mounted) showNotice(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => uploading = false);
      await refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'kin',
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -2,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout),
          onPressed: () async {
            try {
              await widget.repository.client.auth.signOut();
            } catch (_) {
              if (context.mounted) {
                showNotice(context, 'Could not sign out. Retry.');
              }
            }
          },
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const SizedBox(height: 16),
          Text(
            'Your care,\nin context.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          const Text('Private prescriptions. A summary you choose to share.'),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      open(HistoryScreen(repository: widget.repository)),
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      open(SummaryScreen(repository: widget.repository)),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Summary'),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () =>
                      open(FamilyScreen(repository: widget.repository)),
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Family access'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () =>
                      open(ContactScreen(repository: widget.repository)),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Contact QR'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prescriptions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              BusyButton(
                busy: uploading,
                label: 'Add image',
                onPressed: upload,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'One typed English page · JPEG / PNG · up to 5 MB',
            style: TextStyle(fontSize: 12, color: Color(0xff5c7064)),
          ),
          FutureBuilder<List<RecordMap>>(
            future: records,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return KinCard(
                  title: 'Records could not load',
                  child: TextButton(
                    onPressed: refresh,
                    child: const Text('Try again'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.data!.isEmpty) {
                return const KinCard(
                  title: 'Start with one prescription',
                  icon: Icons.description_outlined,
                  child: Text(
                    'Upload a fictional prescription. Extract its fields, compare them with the image, and save what you reviewed.',
                  ),
                );
              }
              return Column(
                children: snapshot.data!
                    .map(
                      (doc) => Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(18),
                          leading: const Icon(Icons.description_outlined),
                          title: Text(doc['clinic'] ?? 'Prescription'),
                          subtitle: Text(
                            '${doc['prescription_date'] ?? 'Date not recorded'}\n${doc['status'] == 'reviewed'
                                ? 'Owner reviewed'
                                : doc['status'] == 'draft'
                                ? 'Draft · needs review'
                                : doc['status'] == 'failed'
                                ? 'Extraction failed · retry or enter manually'
                                : doc['status'] == 'processing'
                                ? 'Extraction in progress'
                                : 'Ready to extract'}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => open(
                            ReviewScreen(
                              repository: widget.repository,
                              document: doc,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Fictional records only · no diagnosis or treatment advice',
            style: TextStyle(fontSize: 12, color: Color(0xff5c7064)),
          ),
        ],
      ),
    ),
  );
}

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
  int section = 0;
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
    appBar: section == 0
        ? AppBar(
            title: const KinBrand(),
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
          )
        : null,
    body: section == 0
        ? RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                const SizedBox(height: 12),
                const Text(
                  'WELCOME TO YOUR CARE SPACE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Color(0xff777780),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your care, in one place.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Keep your records close. Share only what matters.',
                  style: TextStyle(color: Color(0xff777780)),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(23),
                  decoration: BoxDecoration(
                    color: const Color(0xffc4e59a),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const KinBadge(
                        'PRIVATE RECORDS',
                        icon: Icons.lock_outline,
                        dark: true,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Keep a clearer\nrecord of your care.',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: -.7,
                          color: Color(0xff151525),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Add a prescription and check its details.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xff414e32),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: uploading ? null : upload,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xff151525),
                            foregroundColor: Colors.white,
                          ),
                          icon: uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_rounded),
                          label: Text(
                            uploading
                                ? 'Adding prescription…'
                                : 'Add a prescription',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 184,
                        child: KinActionCard(
                          compact: true,
                          title: 'Shared summary',
                          description: 'Choose what your family sees.',
                          icon: Icons.fact_check_outlined,
                          onTap: () => setState(() => section = 2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 184,
                        child: KinActionCard(
                          compact: true,
                          title: 'Contact QR',
                          description: 'Open contacts in any browser.',
                          icon: Icons.qr_code_2_rounded,
                          onTap: () => setState(() => section = 4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prescriptions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () => setState(() => section = 1),
                      child: const Text('View history'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'One typed English page · JPEG / PNG · up to 5 MB',
                  style: TextStyle(fontSize: 12, color: Color(0xff777780)),
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
                          'Add a prescription image above. Your reviewed records will appear here.',
                        ),
                      );
                    }
                    return Column(
                      children: snapshot.data!
                          .map(
                            (doc) => Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(18),
                                leading: Container(
                                  width: 42,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xfff3f3f0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.description_outlined),
                                ),
                                title: Text(
                                  doc['clinic'] ?? 'Prescription',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${doc['prescription_date'] ?? 'Date not recorded'}\n${doc['status'] == 'reviewed'
                                      ? 'Owner reviewed'
                                      : doc['status'] == 'draft'
                                      ? 'Draft · needs review'
                                      : doc['status'] == 'failed'
                                      ? 'Needs review · manual entry available'
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
                  'Your records provide context. They do not recommend treatment.',
                  style: TextStyle(fontSize: 12, color: Color(0xff777780)),
                ),
              ],
            ),
          )
        : switch (section) {
            1 => HistoryScreen(repository: widget.repository),
            2 => SummaryScreen(repository: widget.repository),
            3 => FamilyScreen(repository: widget.repository),
            _ => ContactScreen(repository: widget.repository),
          },
    bottomNavigationBar: NavigationBar(
      selectedIndex: section,
      onDestinationSelected: (value) {
        setState(() => section = value);
        if (value == 0) refresh();
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history_rounded),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.fact_check_outlined),
          selectedIcon: Icon(Icons.fact_check_rounded),
          label: 'Summary',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people_rounded),
          label: 'Family',
        ),
        NavigationDestination(
          icon: Icon(Icons.qr_code_2_rounded),
          label: 'Contact QR',
        ),
      ],
    ),
  );
}

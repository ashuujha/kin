import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/kin_repository.dart';
import '../../core/widgets.dart';
import '../summary/summary_screen.dart';
import '../family/family_screen.dart';
import '../emergency/contact_screen.dart';
import 'review_screen.dart';
import 'history_screen.dart';
import '../reports/reports_screen.dart';
import '../reports/linked_screen.dart';
import '../emergency/medical_screen.dart';

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
      title: const Text('Personal workspace'),
      actions: [
        IconButton(
          tooltip: 'Refresh records',
          onPressed: refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    drawer: Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 30, 24, 8),
              child: Text(
                'YOUR WORKSPACE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  color: Color(0xff60823f),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Text(
                'Health records',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Overview'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ...<({String title, IconData icon, Widget screen})>[
              (
                title: 'Prescriptions',
                icon: Icons.description_outlined,
                screen: HistoryScreen(repository: widget.repository),
              ),
              (
                title: 'Laboratory reports',
                icon: Icons.biotech_outlined,
                screen: ReportsScreen(repository: widget.repository),
              ),
              (
                title: 'Drive & linked files',
                icon: Icons.folder_open_outlined,
                screen: LinkedScreen(repository: widget.repository),
              ),
              (
                title: 'Selected summary',
                icon: Icons.fact_check_outlined,
                screen: SummaryScreen(repository: widget.repository),
              ),
              (
                title: 'Family invitations',
                icon: Icons.people_outline,
                screen: FamilyScreen(repository: widget.repository),
              ),
              (
                title: 'Emergency medical QR',
                icon: Icons.emergency_outlined,
                screen: MedicalScreen(repository: widget.repository),
              ),
              (
                title: 'Contact card',
                icon: Icons.call_outlined,
                screen: ContactScreen(repository: widget.repository),
              ),
            ].map(
              (item) => ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                onTap: () {
                  Navigator.pop(context);
                  open(item.screen);
                },
              ),
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Sign out'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await widget.repository.client.auth.signOut();
                } catch (_) {
                  if (context.mounted) {
                    showNotice(context, 'Could not sign out. Retry.');
                  }
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Fictional records only · hackathon release',
                style: TextStyle(fontSize: 11, color: Color(0xff707079)),
              ),
            ),
          ],
        ),
      ),
    ),
    body: RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          const Text(
            'RECORD OVERVIEW',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              color: Color(0xff60823f),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Your health record.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          const Text(
            'Prescriptions, laboratory results and linked scans. Organized around you.',
            style: TextStyle(color: Color(0xff707079)),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<RecordMap>>(
            future: records,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return KinCard(
                  title: 'Records unavailable',
                  child: TextButton(
                    onPressed: refresh,
                    child: const Text('Retry'),
                  ),
                );
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final docs = snapshot.data!;
              final reviewed = docs
                  .where((d) => d['status'] == 'reviewed')
                  .length;
              return Row(
                children: [
                  Expanded(
                    child: KinCard(
                      title: 'Prescriptions',
                      child: Text(
                        '${docs.length}',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KinCard(
                      title: 'Reviewed',
                      child: Text(
                        '$reviewed',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Add to your record',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          KinActionCard(
            title: 'Prescription',
            description: 'Upload an image and review its details.',
            icon: Icons.add_photo_alternate_outlined,
            onTap: upload,
          ),
          if (uploading) const LinearProgressIndicator(),
          KinActionCard(
            title: 'Laboratory report',
            description: 'Import a PDF or image. View extracted results.',
            icon: Icons.biotech_outlined,
            onTap: () => open(ReportsScreen(repository: widget.repository)),
          ),
          KinActionCard(
            title: 'Drive & linked scans',
            description: 'Keep large DICOM files in your own storage.',
            icon: Icons.folder_open_outlined,
            onTap: () => open(LinkedScreen(repository: widget.repository)),
          ),
          const SizedBox(height: 24),
          Text(
            'Access, when it matters',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          KinActionCard(
            title: 'Emergency medical QR',
            description: 'Optional selected medical access without login.',
            icon: Icons.emergency_outlined,
            onTap: () => open(MedicalScreen(repository: widget.repository)),
          ),
          KinActionCard(
            title: 'Family invitations',
            description: 'Private, account-bound access for 24 hours.',
            icon: Icons.people_outline,
            onTap: () => open(FamilyScreen(repository: widget.repository)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Extracted details require your review. Prescription entries do not establish current medication use.',
            style: TextStyle(fontSize: 12, color: Color(0xff707079)),
          ),
        ],
      ),
    ),
  );
}

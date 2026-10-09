import 'package:flutter/material.dart';

import '../../core/kin_repository.dart';
import '../../core/widgets.dart';
import '../../core/link_sheet.dart';

class ContactEditor {
  ContactEditor(RecordMap value)
    : name = TextEditingController(text: value['name']),
      relationship = TextEditingController(text: value['relationship']),
      phone = TextEditingController(text: value['phone']);
  final TextEditingController name, relationship, phone;
  RecordMap get value => {
    'name': name.text.trim(),
    'relationship': relationship.text.trim(),
    'phone': phone.text.trim(),
  };
  void dispose() {
    name.dispose();
    relationship.dispose();
    phone.dispose();
  }
}

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key, required this.repository});
  final KinRepository repository;
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final contacts = <ContactEditor>[];
  bool loading = true, busy = false, failed = false;
  String? link;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await widget.repository.contacts();
      final saved = await widget.repository.contactLink();
      if (!mounted) return;
      setState(() {
        name.text = data?['display_name'] ?? '';
        contacts.addAll(
          List<RecordMap>.from(data?['entries'] ?? []).map(ContactEditor.new),
        );
        if (contacts.isEmpty) contacts.add(ContactEditor({}));
        link = saved;
        loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          failed = true;
        });
      }
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final url = await widget.repository.saveContacts(
        name.text.trim(),
        contacts.map((c) => c.value).toList(),
      );
      if (mounted) {
        setState(() => link = url);
        await showLink(
          context,
          title: 'Public contact QR',
          url: url,
          explanation: 'Anyone with this QR can view these contacts without sign-in. No medical information is included. Previous contact links are now invalid.',
        );
      }
    } catch (error) {
      if (mounted) showNotice(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> revoke() async {
    setState(() => busy = true);
    try {
      await widget.repository.revokeContacts(
        name.text.trim(),
        contacts.map((c) => c.value).toList(),
      );
      if (mounted) {
        setState(() => link = null);
        showNotice(context, 'Contact link revoked.');
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
    for (final c in contacts) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Emergency contacts')),
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
                const KinCard(
                  title: 'Contacts in a scan',
                  icon: Icons.qr_code,
                  child: Text(
                    'A separate public card for reaching people you trust. Anyone with the QR can read it in a browser. Ask contacts before publishing their number. Medical information stays private.',
                  ),
                ),
                const SizedBox(height: 16),
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
                ...contacts.asMap().entries.map((entry) {
                  final c = entry.value;
                  return KinCard(
                    title: 'Contact ${entry.key + 1}',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: c.name,
                          maxLength: 120,
                          decoration: const InputDecoration(
                            labelText: 'Contact name',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Name is required.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: c.relationship,
                          maxLength: 80,
                          decoration: const InputDecoration(
                            labelText: 'Relationship · optional',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: c.phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                          ),
                          validator: (v) =>
                              RegExp(r'^\+?[0-9 ()-]{5,25}$')
                                  .hasMatch(v?.trim() ?? '')
                              ? null
                              : 'Enter a valid phone number.',
                        ),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => setState(() {
                                  contacts.removeAt(entry.key);
                                  c.dispose();
                                }),
                          child: const Text('Remove contact'),
                        ),
                      ],
                    ),
                  );
                }),
                if (contacts.length < 5)
                  TextButton.icon(
                    onPressed: busy
                        ? null
                        : () => setState(() => contacts.add(ContactEditor({}))),
                    icon: const Icon(Icons.add),
                    label: const Text('Add contact'),
                  ),
                const SizedBox(height: 16),
                BusyButton(
                  busy: busy,
                  label: 'Save and create new QR',
                  onPressed: save,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Saving rotates the QR. Older printed or shared QR codes stop working. A contact QR remains active until rotated or revoked.',
                ),
                if (link != null) ...[
                  OutlinedButton(
                    onPressed: () => showLink(
                      context,
                      title: 'Public contact QR',
                      url: link!,
                      explanation:
                          'Contacts only · no sign-in · internet required.',
                    ),
                    child: const Text('Show current QR'),
                  ),
                  TextButton(
                    onPressed: busy ? null : revoke,
                    child: const Text('Revoke contact QR'),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Kin does not bypass a locked phone. You can print this QR or place it somewhere accessible.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
  );
}

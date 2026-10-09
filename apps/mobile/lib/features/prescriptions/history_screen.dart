import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/kin_repository.dart';
import '../../core/widgets.dart';
import 'date_range.dart';
import 'review_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.repository});
  final KinRepository repository;
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> names = [];
  String? medicine;
  String range = 'all';
  DateTime? from, to;
  late Future<RecordMap> results;
  @override
  void initState() {
    super.initState();
    results = widget.repository.search();
    loadNames();
  }

  Future<void> loadNames() async {
    try {
      final data = await widget.repository.search();
      if (mounted) {
        setState(
          () => names = List<RecordMap>.from(
            data['matches'],
          ).map((m) => m['name'] as String).toSet().toList()..sort(),
        );
      }
    } catch (_) {}
  }

  void query() {
    setState(
      () => results = widget.repository.search(
        medicine: medicine,
        from: from,
        to: to,
      ),
    );
  }

  Future<void> selectRange(String value) async {
    if (value == 'custom') {
      final selection = await showDateRangePicker(
        context: context,
        firstDate: DateTime(1900),
        lastDate: DateTime.now().add(const Duration(days: 366)),
        initialDateRange: from != null && to != null
            ? DateTimeRange(start: from!, end: to!)
            : null,
      );
      if (selection == null) return;
      from = selection.start;
      to = selection.end;
    } else if (value == 'all') {
      from = null;
      to = null;
    } else {
      final dates = calendarMonth(DateTime.now(), previous: value == 'last');
      from = dates.from;
      to = dates.to;
    }
    range = value;
    query();
  }

  Future<void> source(String id) async {
    try {
      final records = await widget.repository.documents();
      final doc = records.firstWhere((d) => d['id'] == id);
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                ReviewScreen(repository: widget.repository, document: doc),
          ),
        );
      }
      query();
    } catch (failure) {
      if (mounted) showNotice(context, friendlyError(failure));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Prescription history')),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Search owner-reviewed records. Different prescriptions stay separate; no dose is inferred.',
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          initialValue: medicine,
          decoration: const InputDecoration(labelText: 'Medicine'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All medicines'),
            ),
            ...names.map(
              (name) => DropdownMenuItem(value: name, child: Text(name)),
            ),
          ],
          onChanged: (v) {
            medicine = v;
            query();
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: range,
          decoration: const InputDecoration(labelText: 'Prescription date'),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All dates')),
            DropdownMenuItem(value: 'this', child: Text('This month')),
            DropdownMenuItem(value: 'last', child: Text('Last calendar month')),
            DropdownMenuItem(value: 'custom', child: Text('Custom range')),
          ],
          onChanged: (v) {
            if (v != null) selectRange(v);
          },
        ),
        if (from != null && to != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              '${DateFormat.yMMMd().format(from!)} – ${DateFormat.yMMMd().format(to!)}',
            ),
          ),
        const SizedBox(height: 20),
        FutureBuilder<RecordMap>(
          future: results,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return KinCard(
                title: 'History could not load',
                child: TextButton(onPressed: query, child: const Text('Retry')),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final matches = List<RecordMap>.from(snapshot.data!['matches']);
            return Column(
              children: [
                if ((snapshot.data!['undated_count'] as int) > 0)
                  KinCard(
                    title: 'Date not recorded',
                    child: Text(
                      '${snapshot.data!['undated_count']} matching entries have no prescription date.${from != null ? ' Select All dates to view them.' : ''}',
                    ),
                  ),
                if (matches.isEmpty)
                  const KinCard(
                    title: 'No matching reviewed record',
                    child: Text(
                      'This does not establish that a medicine was never prescribed.',
                    ),
                  ),
                ...matches.map(
                  (m) => KinCard(
                    title: m['name'],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescription: ${m['prescription_date'] ?? 'Date unknown'}',
                        ),
                        Text('Dosage: ${m['dosage'] ?? 'Not recorded'}'),
                        Text('Frequency: ${m['frequency'] ?? 'Not recorded'}'),
                        Text('Duration: ${m['duration'] ?? 'Not recorded'}'),
                        Text(
                          'Owner-reported use: ${m['taking_status'] == 'taking'
                              ? 'Taking'
                              : m['taking_status'] == 'stopped'
                              ? 'Stopped'
                              : 'Not confirmed'}',
                        ),
                        TextButton(
                          onPressed: () => source(m['document_id']),
                          child: const Text('View private source'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

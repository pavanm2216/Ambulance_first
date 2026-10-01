import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

class DoctorRosterScreen extends StatefulWidget {
  const DoctorRosterScreen({super.key});

  @override
  State<DoctorRosterScreen> createState() => _DoctorRosterScreenState();
}

class _DoctorRosterScreenState extends State<DoctorRosterScreen> {
  bool _loading = true;
  String? _error;
  String _search = '';
  String _status = 'ALL';
  List<Map<String, dynamic>> _doctors = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Use the Team Lead read RPC so doctor records come from the
      // authoritative Supabase source without depending on direct table RLS.
      final rows = await SupabaseService.client.rpc(
        'get_team_lead_doctors',
      );

      if (!mounted) return;
      setState(() {
        _doctors = _maps(rows);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> _maps(dynamic rows) {
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.trim().toLowerCase();

    return _doctors.where((d) {
      final status = '${d['status'] ?? ''}'.toUpperCase();

      if (_status != 'ALL' && status != _status) {
        return false;
      }

      if (q.isEmpty) return true;

      return '${d['full_name'] ?? ''}'.toLowerCase().contains(q) ||
          '${d['specialization'] ?? ''}'.toLowerCase().contains(q) ||
          '${d['phone'] ?? ''}'.toLowerCase().contains(q);
    }).toList();
  }

  bool _available(String value) {
    final s = value.toUpperCase();

    return s == 'AVAILABLE' ||
        s == 'READY' ||
        s == 'ON_DUTY' ||
        s == 'ONLINE' ||
        s == 'ON_CALL';
  }

  @override
  Widget build(BuildContext context) {
    final doctors = _filtered;
    final available =
        _doctors.where((d) => _available('${d['status'] ?? ''}')).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Doctors'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_doctors.length} doctors • $available available/on-call',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            onChanged: (v) => setState(() => _search = v),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Search doctor or specialization',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              children: [
                                for (final s in const [
                                  'ALL',
                                  'AVAILABLE',
                                  'ON_CALL',
                                  'ASSIGNED',
                                  'OFF_DUTY',
                                ])
                                  ChoiceChip(
                                    label: Text(s.replaceAll('_', ' ')),
                                    selected: _status == s,
                                    onSelected: (_) =>
                                        setState(() => _status = s),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: doctors.isEmpty
                          ? const Center(
                              child: Text(
                                'No doctors found in the live database.',
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: doctors.length,
                              itemBuilder: (_, i) => _card(doctors[i]),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _card(Map<String, dynamic> d) {
    final name = '${d['full_name'] ?? 'Unnamed doctor'}';
    final specialization =
        '${d['specialization'] ?? 'Specialization not recorded'}';
    final status = '${d['status'] ?? 'UNKNOWN'}'.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEAF4FA),
          child: Text(
            name.isEmpty ? 'D' : name.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '$specialization\n${d['phone'] ?? 'Phone not recorded'}',
          ),
        ),
        trailing: _badge(status),
      ),
    );
  }

  Widget _badge(String status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: _available(status)
              ? const Color(0xFFE7F7EF)
              : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status.replaceAll('_', ' '),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

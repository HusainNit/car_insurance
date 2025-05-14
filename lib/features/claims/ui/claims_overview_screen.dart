// lib/features/claims/ui/claims_overview_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/widgets/main_scaffold.dart';
import '../../../core/widgets/ui_helpers.dart';
import 'claim_info_screen.dart';
import 'claim_detail_screen.dart';

class ClaimsOverviewScreen extends StatefulWidget {
  const ClaimsOverviewScreen({super.key});

  @override
  State<ClaimsOverviewScreen> createState() => _ClaimsOverviewScreenState();
}

class _ClaimsOverviewScreenState extends State<ClaimsOverviewScreen> {
  String selectedStatus = 'All';
  static const statuses = ['All', 'Pending', 'Approved', 'Rejected'];

  String? _role; // 'admin' | 'customer'

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() => _role =
        (snap.data()?['userType'] ?? snap.data()?['role'] ?? 'customer')
            .toString());
  }

  Query<Map<String, dynamic>> _baseQuery() =>
      FirebaseFirestore.instance.collection('claims');

  @override
  Widget build(BuildContext context) {
    if (_role == null) return const Center(child: CircularProgressIndicator());

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final query = _role == 'admin'
        ? _baseQuery().orderBy('submittedAt', descending: true)
        : _baseQuery().where('createdBy', isEqualTo: uid);

    return MainScaffold(
      selectedIndex: 2,
      title: _role == 'admin' ? 'All Claims' : 'My Claims',
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Review and manage your claims',
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
              ),
              const SizedBox(height: 12),
              _statusChips(),
              const SizedBox(height: 12),
              Expanded(child: _claimsList(query)),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClaimInfoScreen()),
              ),
              backgroundColor: accentColor, 
              foregroundColor: Colors.black,
              mini: true,
              child: const Icon(Icons.add, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: statuses.map((s) {
            final sel = s == selectedStatus;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s),
                selected: sel,
                onSelected: (_) => setState(() => selectedStatus = s),
                showCheckmark: false,
                backgroundColor: Colors.white12,
                selectedColor: accentColor,
                labelStyle: TextStyle(
                  color: sel ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _claimsList(Query<Map<String, dynamic>> query) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return customLoadingSpinner();
          }
          if (snap.hasError) {
            return Center(
                child: Text('Firestore error: ${snap.error}',
                    style: const TextStyle(color: Colors.redAccent)));
          }

          var docs = snap.data?.docs ?? [];

          docs.sort((a, b) {
            final tsA = a['submittedAt'] as Timestamp?;
            final tsB = b['submittedAt'] as Timestamp?;
            return (tsB?.seconds ?? 0).compareTo(tsA?.seconds ?? 0);
          });

          if (selectedStatus != 'All') {
            docs = docs.where((d) {
              final s = (d['status'] ?? 'Pending').toString().toLowerCase();
              return s == selectedStatus.toLowerCase();
            }).toList();
          }

          if (docs.isEmpty) {
            return const Center(
                child: Text('No claims found.',
                    style: TextStyle(color: Colors.white70, fontSize: 16)));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: docs.length,
            itemBuilder: (_, i) => _ClaimCard(doc: docs[i]),
          );
        },
      );
}


class _ClaimCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _ClaimCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final regNum =
        data['registrationNum'] as String? ?? data['vin'] as String? ?? '—';
    final location = data['location'] ?? 'Unknown';
    final cost = (data['repairCost'] ?? 0).toDouble();
    final status = (data['status'] ?? 'Pending') as String;
    final parsedDate =
        DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy').format(parsedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        color: const Color(0xFF262626),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClaimDetailScreen(claimDoc: doc),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 140,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        future: doc.reference
                            .collection('photos')
                            .orderBy('ts')
                            .limit(1)
                            .get(),
                        builder: (_, snap) {
                          if (snap.hasData && snap.data!.docs.isNotEmpty) {
                            return Image.network(
                              snap.data!.docs.first['url'] as String,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            );
                          }
                          return Container(color: Colors.grey.shade800);
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _StatusChip(status: status),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            regNum,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _iconText(Icons.calendar_today, dateStr),
                        const SizedBox(height: 8),
                        _iconText(
                          Icons.attach_money,
                          cost.toStringAsFixed(2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: Colors.white60),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status.toLowerCase()) {
      case 'approved':
        bg = Colors.greenAccent;
        fg = Colors.black;
        break;
      case 'rejected':
        bg = Colors.redAccent;
        fg = Colors.white;
        break;
      default:
        bg = Colors.orangeAccent;
        fg = Colors.black;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

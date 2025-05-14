// lib/features/claims/ui/claims_overview_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      selectedIndex: 2,
      title: 'All Claims',
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // ─── Subtitle ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Review and manage your claims',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ─── Status Filter Chips ─────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: statuses.map((status) {
                    final isSelected = status == selectedStatus;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => selectedStatus = status),
                        showCheckmark: false, // ← disable the tick
                        backgroundColor: Colors.white12,
                        selectedColor: accentColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // ─── Claims List ─────────────────────────────
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('claims')
                      .orderBy('submittedAt', descending: true)
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return customLoadingSpinner();
                    }
                    final docs = snap.data?.docs ?? [];
                    final filtered = selectedStatus == 'All'
                        ? docs
                        : docs.where((doc) {
                            final st =
                                (doc.data()['status'] ?? 'Pending').toString();
                            return st.toLowerCase() ==
                                selectedStatus.toLowerCase();
                          }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'No claims found.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _ClaimCard(doc: filtered[i]),
                    );
                  },
                ),
              ),
            ],
          ),

          // ─── New Claim FAB ────────────────────────────
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClaimInfoScreen()),
              ),
              backgroundColor: accentColor.withOpacity(0.95),
              foregroundColor: Colors.black,
              elevation: 4,
              mini: true,
              child: const Icon(Icons.add, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single Claim Card
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ClaimDetailScreen(claimDoc: doc)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner + Status Chip
              SizedBox(
                height: 140,
                child: Stack(children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
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
                ]),
              ),

              // Body: regNum & location / date & cost
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    // Left: regNum + location
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

                    // Right: date & cost
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _iconText(Icons.calendar_today, dateStr),
                        const SizedBox(height: 8),
                        _iconText(Icons.attach_money, cost.toStringAsFixed(2)),
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
          Text(text,
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      );
}

/// Status Chip Overlay
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:car_insurance_app/core/constants.dart';
import 'package:car_insurance_app/core/widgets/ui_helpers.dart';

class ReviewClaimsScreen extends StatefulWidget {
  const ReviewClaimsScreen({super.key});

  @override
  State<ReviewClaimsScreen> createState() => _ReviewClaimsScreenState();
}

class _ReviewClaimsScreenState extends State<ReviewClaimsScreen> {
  bool _showPendingOnly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, 'Review Claims'),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('claims')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return customLoadingSpinner();
          }
          if (!snap.hasData) {
            return const Center(
              child: Text(
                'No claims collection found.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final allDocs = snap.data!.docs;
          final pendingDocs = allDocs
              .where((d) => (d.data()['status'] as String? ?? '') == 'Pending')
              .toList();

          return Column(
            children: [
              // ⚙️ Debug info and toggle
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      'Total: ${allDocs.length}   Pending: ${pendingDocs.length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const Spacer(),
                    Text(
                      'Show Pending',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Switch(
                      value: _showPendingOnly,
                      onChanged: (v) => setState(() => _showPendingOnly = v),
                      activeColor: accentColor,
                    ),
                  ],
                ),
              ),

              // Show message if no docs in chosen filter
              if ((_showPendingOnly && pendingDocs.isEmpty) ||
                  (!_showPendingOnly && allDocs.isEmpty))
                Expanded(
                  child: Center(
                    child: Text(
                      _showPendingOnly
                          ? 'No pending claims found.'
                          : 'No claims found.',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                )
              else
                // The list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        _showPendingOnly ? pendingDocs.length : allDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final doc =
                          _showPendingOnly ? pendingDocs[i] : allDocs[i];
                      return _ClaimCard(doc: doc);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ClaimCard extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _ClaimCard({required this.doc});

  @override
  State<_ClaimCard> createState() => _ClaimCardState();
}

class _ClaimCardState extends State<_ClaimCard> {
  bool _processing = false;

  Future<void> _setStatus(String newStatus) async {
    setState(() => _processing = true);
    try {
      await widget.doc.reference.update({
        'status': newStatus,
        'adminApproval': newStatus == 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Claim ${newStatus.toUpperCase()}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final vin = data['vin'] as String? ?? '—';
    final loc = data['location'] as String? ?? '—';
    final cost = (data['repairCost'] ?? 0).toDouble();
    final rate = ((data['consumptionRate'] ?? 0.0) as num).toDouble() * 100.0;
    final parts =
        (data['damagedParts'] as List<dynamic>?)?.cast<String>().join(', ') ??
            '—';
    final dt =
        DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(dt);

    return Card(
      color: const Color(0xFF262626),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // thumbnail
        FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: widget.doc.reference
              .collection('photos')
              .orderBy('ts')
              .limit(1)
              .get(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final pd = snap.data?.docs;
            if (pd != null && pd.isNotEmpty) {
              return Image.network(
                pd.first['url'] as String,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              );
            }
            return Container(
              height: 140,
              color: Colors.grey.shade800,
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported,
                  color: Colors.white24, size: 40),
            );
          },
        ),

        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _infoRow('VIN', vin),
              _infoRow('Location', loc),
              _infoRow('Date', dateStr),
              _infoRow('Cost (BHD)', cost.toStringAsFixed(2)),
              _infoRow('Consumption Rate', '${rate.toStringAsFixed(1)}%'),
              _infoRow('Damaged Parts', parts),
              const SizedBox(height: 12),
              if (_processing)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => _setStatus('approved'),
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _setStatus('rejected'),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(
              '$label:',
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
      );
}

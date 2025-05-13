import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/ui_helpers.dart';

class ClaimDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> claimDoc;
  const ClaimDetailScreen({super.key, required this.claimDoc});

  @override
  Widget build(BuildContext context) {
    final d = claimDoc.data();
    final parsedDate =
        DateTime.tryParse(d['date'] as String? ?? '') ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(parsedDate);

    return Scaffold(
      appBar: customAppBar(context, 'Claim Details'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          sectionTitle('Overview'),
          infoCard([
            infoRow('VIN', d['vin'] ?? ''),
            infoRow('Policy', d['policy'] ?? ''),
            infoRow('Location', d['location'] ?? ''),
            infoRow('Date', dateStr),
            infoRow('Time', d['time'] ?? ''),
            infoRow('Cost (BHD)', d['repairCost']?.toString() ?? ''),
            infoRow('Status', d['status'] ?? 'Pending'),
            infoRow('Consumption Rate', '${d['consumptionRate'] ?? ''}'),
            infoRow('Damaged Parts',
                (d['damagedParts'] as List<dynamic>? ?? []).join(', ')),
            infoRow('Description', d['description'] ?? ''),
          ]),
          const SizedBox(height: 24),
          sectionTitle('Photos'),
          _PhotoGrid(claimDoc: claimDoc),
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> claimDoc;
  const _PhotoGrid({required this.claimDoc});

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: claimDoc.reference
            .collection('photos')
            .orderBy('ts')
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return customLoadingSpinner();
          final urls = snap.data!.docs.map((d) => d['url'] as String).toList();
          if (urls.isEmpty) {
            return const Center(child: Text('No photos attached'));
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: urls.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(urls[i], fit: BoxFit.cover),
            ),
          );
        },
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/ui_helpers.dart';

class SubmitScreen extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> claimDoc;
  const SubmitScreen({super.key, required this.claimDoc});

  Future<void> _submit(BuildContext context) async {
    await claimDoc.update({
      'status': 'Pending',
      'submitted': true,
      'submittedAt': FieldValue.serverTimestamp(),
    });
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submitted!'),
        content:
            const Text('Your claim has been sent to the insurance company.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: customAppBar(context, 'Review & Submit'),
        body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: claimDoc.get(),
          builder: (_, snap) {
            if (!snap.hasData) return customLoadingSpinner();
            final data = snap.data!.data()!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                sectionTitle('Claim Details'),
                infoCard([
                  infoRow('VIN', data['vin']),
                  infoRow('Policy', data['policy']),
                  infoRow('Location', data['location']),
                  infoRow('Date', data['date']),
                  infoRow('Time', data['time']),
                  infoRow('Repair Cost (BHD)',
                      data['repairCost']?.toString() ?? ''),
                  infoRow('Status', data['status']),
                ]),
                const SizedBox(height: 20),
                sectionTitle('Attached Photos'),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: claimDoc.collection('photos').snapshots(),
                  builder: (_, s) {
                    if (!s.hasData) return const SizedBox.shrink();
                    final urls =
                        s.data!.docs.map((d) => d['url'] as String).toList();
                    if (urls.isEmpty) {
                      return const Center(child: Text('No photos attached'));
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: urls.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemBuilder: (_, i) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(urls[i], fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child:
                customFilledButton('Submit Claim  ››', () => _submit(context)),
          ),
        ),
      );
}

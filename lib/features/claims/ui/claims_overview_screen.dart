import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:car_insurance_app/core/constants.dart';
import 'package:car_insurance_app/core/widgets/main_scaffold.dart';
import 'package:car_insurance_app/core/widgets/ui_helpers.dart';
import 'package:car_insurance_app/features/claims/ui/claim_info_screen.dart';

class ClaimsOverviewScreen extends StatelessWidget {
  const ClaimsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      selectedIndex: 2,
      title: 'Your Claims',
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 96),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('claims')
                  .orderBy('submittedAt', descending: true)
                  .snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return customLoadingSpinner();
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const _EmptyState();
                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ClaimCard(doc: docs[i]),
                );
              },
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: _NewClaimButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClaimInfoScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          'No claims yet.\nTap the ➕ button to start.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4),
        ),
      );
}

class _NewClaimButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _NewClaimButton({required this.onPressed});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add, color: Colors.black, size: 26),
              SizedBox(width: 8),
              Text('New Claim',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ],
          ),
        ),
      );
}

class _ClaimCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _ClaimCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final policy = d['policy'] ?? 'Unknown Policy';
    final location = d['location'] ?? 'Unknown';
    final parsedDate =
        DateTime.tryParse(d['date'] as String? ?? '') ?? DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy').format(parsedDate);
    final cost = (d['repairCost'] ?? 0).toDouble();
    final low = d['expectedLow'] == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {}, // TODO: navigate to detail
        child: Ink(
          height: 230,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF222428), Color(0xFF1B1C1F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBanner(doc: doc, title: policy),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  location,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
              const Spacer(),
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(22)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoChip(Icons.calendar_today, dateStr),
                    _infoChip(
                        Icons.attach_money, 'BHD ${cost.toStringAsFixed(2)}'),
                    _infoChip(Icons.scale, low ? '≤500' : '>500',
                        bg: low ? accentColor : Colors.redAccent,
                        fg: Colors.black),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData ic, String txt,
          {Color bg = Colors.white12, Color fg = Colors.white}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(ic, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(txt,
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      );
}

class _TopBanner extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String title;
  const _TopBanner({required this.doc, required this.title});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: doc.reference.collection('photos').orderBy('ts').limit(1).get(),
      builder: (_, snap) {
        Widget image;
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          final url = snap.data!.docs.first['url'] as String;
          image = Image.network(url, fit: BoxFit.cover);
        } else {
          image = Container(color: Colors.grey.shade800);
        }
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              SizedBox(height: 120, width: double.infinity, child: image),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black54],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                          color: Colors.black38,
                          offset: Offset(0, 1),
                          blurRadius: 3)
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

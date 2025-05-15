// lib/features/policies/ui/policies_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:car_insurance_app/core/widgets/main_scaffold.dart';
import 'package:car_insurance_app/core/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PoliciesScreen extends StatefulWidget {
  const PoliciesScreen({super.key});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen> {
  final _regController = TextEditingController();
  int? _selectedYear;
  List<Map<String, dynamic>> _current = [];
  List<Map<String, dynamic>> _past = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;


  static final _years = <int?>[
    null,
    for (var i = 0; i < 10; i++) DateTime.now().year - i,
  ];

  @override
  void initState() {
    super.initState();
   
    _regController.addListener(() {
      Future.delayed(const Duration(milliseconds: 300), _fetchPolicies);
    });
    _fetchPolicies();
  }

  @override
  void dispose() {
    _regController.dispose();
    super.dispose();
  }

  Future<void> _fetchPolicies() async {
    final User? user = _auth.currentUser;

    final now = DateTime.now();
    final query = _regController.text.trim().toLowerCase();
    final vehicles =
        await FirebaseFirestore.instance.collection('vehicles').get();
    final reqs =
        await FirebaseFirestore.instance.collection('InsuranceReq').get();

    final vinMap = {
      for (var d in vehicles.docs)
        (d['vin'] as String).toLowerCase():
            (d['registrationNumber'] as String).toUpperCase(),
    };

    final curr = <Map<String, dynamic>>[];
    final pastl = <Map<String, dynamic>>[];

    for (var doc in reqs.docs) {
      final m = doc.data();
      final vin = (m['vehicleId'] as String).toLowerCase();
      final reg = vinMap[vin] ?? '';
      if (reg.isEmpty) continue;
      if (m['insuranceStatus'] != null && m['insuranceStatus'] != 'Approved') continue;



      final pd = m['policyDetails'] as Map<String, dynamic>? ?? {};
      final start = DateTime.tryParse(pd['startDate'] ?? '');
      final end = DateTime.tryParse(pd['endDate'] ?? '');
      final num = pd['policyNum']?.toString() ?? '';
      if (start == null || end == null || num.isEmpty) continue;

      if ((query.isNotEmpty && !reg.toLowerCase().contains(query)) ||
          (_selectedYear != null && start.year != _selectedYear)) {
        continue;
      }
      
      final rec = {
        'policyNum': num,
        'regNum': reg,
        'start': start,
        'end': end,
      };

      if (end.isAfter(now)) {
          print(user);
        if(user?.uid == m['userId']) {
          curr.add(rec);
        }
      } else {
          print(user);
        if(user?.uid == m['userId']) {
          pastl.add(rec);
        }
      }
    }

    setState(() {
      _current = curr;
      _past = pastl;
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: MainScaffold(
        selectedIndex: 3,
        title: 'Your Policies',
        body: Column(
          children: [
            // 1 Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _regController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by Reg. Number',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF282828),
                  prefixIcon:
                      const Icon(Icons.directions_car, color: accentColor),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () {
                      _regController.clear();
                      _fetchPolicies();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // 2 Year Filter Pills
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _years.length,
                itemBuilder: (_, idx) {
                  final y = _years[idx];
                  final label = y == null ? 'All Years' : y.toString();
                  final selected = y == _selectedYear;

                  return InkWell(
                    onTap: () {
                      setState(() => _selectedYear = y);
                      _fetchPolicies();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? accentColor : const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected ? Colors.black : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 3 Tabs
            TabBar(
              indicatorColor: accentColor,
              labelColor: accentColor,
              unselectedLabelColor: Colors.white70,
              labelPadding: const EdgeInsets.symmetric(horizontal: 24),
              tabs: [
                Tab(text: 'Current (${_current.length})'),
                Tab(text: 'Past    (${_past.length})'),
              ],
            ),

            // 4 Tab Views
            Expanded(
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildList(_current, 'No active policies'),
                  _buildList(_past, 'No past policies'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, String emptyMsg) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMsg,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _policyCard(items[i]),
    );
  }

  Widget _policyCard(Map<String, dynamic> p) {
    final fmt = DateFormat('yyyy-MM-dd');
    return Card(
      color: const Color(0xFF242424),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(p['policyNum'] ?? '',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Reg: ${p['regNum']}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Text(
              '${fmt.format(p['start'])} → ${fmt.format(p['end'])}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

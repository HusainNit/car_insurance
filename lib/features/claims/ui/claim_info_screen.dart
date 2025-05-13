// lib/features/claims/ui/claim_info_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/claim_model.dart';
import 'damage_location_screen.dart';
import '../../../core/constants.dart';
import '../../../core/widgets/ui_helpers.dart';

class ClaimInfoScreen extends StatefulWidget {
  const ClaimInfoScreen({super.key});

  @override
  State<ClaimInfoScreen> createState() => _ClaimInfoScreenState();
}

class _ClaimInfoScreenState extends State<ClaimInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all fields, including policy
  final _policyController = TextEditingController();
  final _locController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;

  late Future<List<String>> _vinsFuture;
  String? _selectedVin;

  @override
  void initState() {
    super.initState();
    _vinsFuture = FirebaseFirestore.instance
        .collection('vehicles')
        .orderBy('vin')
        .get()
        .then((snap) => snap.docs.map((d) => d['vin'] as String).toList());
  }

  @override
  void dispose() {
    _policyController.dispose();
    _locController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, 'Submit Accident'),
      body: FutureBuilder<List<String>>(
        future: _vinsFuture,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return customLoadingSpinner();
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to load vehicles'));
          }
          final vins = snap.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // VIN dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedVin,
                    decoration: _fieldDeco('Select Vehicle (VIN)'),
                    items: vins.map((vin) {
                      return DropdownMenuItem(value: vin, child: Text(vin));
                    }).toList(),
                    onChanged: (vin) async {
                      setState(() => _selectedVin = vin);
                      _policyController.clear();
                      if (vin != null) {
                        final req = await FirebaseFirestore.instance
                            .collection('InsuranceReq')
                            .where('vehicleId', isEqualTo: vin)
                            .limit(1)
                            .get();
                        if (req.docs.isNotEmpty) {
                          final pd = req.docs.first.data()['policyDetails']
                              as Map<String, dynamic>;
                          _policyController.text = pd['policyNum'] as String;
                        }
                      }
                    },
                    validator: (v) =>
                        v == null ? 'Please choose a vehicle' : null,
                  ),

                  const SizedBox(height: 16),

                  // Policy number (read-only)
                  TextFormField(
                    controller: _policyController,
                    readOnly: true,
                    decoration: _fieldDeco('Policy Number'),
                    validator: (_) => _policyController.text.isEmpty
                        ? 'No policy found'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Accident location
                  customInputField(
                    'Accident Location',
                    _locController,
                    suffix: const Icon(Icons.place, color: accentColor),
                  ),

                  const SizedBox(height: 16),

                  // Date & Time
                  Row(children: [
                    Expanded(
                      child: _datePicker(
                        context,
                        'Date',
                        _date == null
                            ? ''
                            : DateFormat('yyyy-MM-dd').format(_date!),
                        () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _datePicker(
                        context,
                        'Time',
                        _time?.format(context) ?? '',
                        () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _time ?? TimeOfDay.now(),
                          );
                          if (picked != null) setState(() => _time = picked);
                        },
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Description
                  customInputField('Short Description', _descController,
                      maxLines: 3),

                  const SizedBox(height: 16),

                  // Repair cost
                  customInputField(
                    'Estimated Repair Cost (BHD)',
                    _priceController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Enter a repair cost';
                      }
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  customFilledButton('Next ››', _onNext),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onNext() {
    if (_formKey.currentState?.validate() != true) return;
    final baseClaim = ClaimModel(
      vin: _selectedVin!,
      policy: _policyController.text,
      location: _locController.text.trim(),
      description: _descController.text.trim(),
      date: _date ?? DateTime.now(),
      time: _time ?? TimeOfDay.now(),
      repairCost: double.parse(_priceController.text),
      damagedParts: [], // collected later
      consumptionRate: 0.10, // default until photos processed
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DamageLocationScreen(claim: baseClaim),
      ),
    );
  }

  InputDecoration _fieldDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF282828),
        labelStyle: const TextStyle(color: Colors.white70),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: accentColor, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      );

  Widget _datePicker(
    BuildContext ctx,
    String lbl,
    String txt,
    VoidCallback onTap,
  ) =>
      datePickerField(ctx, lbl, TextEditingController(text: txt), onTap);
}

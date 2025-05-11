import 'package:flutter/material.dart';
import 'package:car_insurance_app/core/widgets/ui_helpers.dart';
import '../models/claim_model.dart';
import 'damage_location_screen.dart';
import 'package:car_insurance_app/core/constants.dart';

class ClaimInfoScreen extends StatefulWidget {
  const ClaimInfoScreen({super.key});

  @override
  State<ClaimInfoScreen> createState() => _ClaimInfoScreenState();
}

class _ClaimInfoScreenState extends State<ClaimInfoScreen> {
  final _fKey = GlobalKey<FormState>();
  final _vin = TextEditingController();
  final _policy = TextEditingController();
  final _loc = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  bool _low = true;

  @override
  void dispose() {
    _vin.dispose();
    _policy.dispose();
    _loc.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: customAppBar(context, 'Claim Information'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Form(
            key: _fKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                customInputField('VIN Number', _vin),
                const SizedBox(height: 18),
                customInputField('Policy Number', _policy),
                const SizedBox(height: 18),
                customInputField('Accident Location', _loc,
                    suffix: const Icon(Icons.place, color: accentColor)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: datePickerField(
                        context,
                        'Date',
                        TextEditingController(
                          text: _date == null
                              ? ''
                              : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
                        ),
                        () async {
                          final p = await showDatePicker(
                              context: context,
                              initialDate: _date ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now());
                          if (p != null) setState(() => _date = p);
                        },
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: datePickerField(
                        context,
                        'Time',
                        TextEditingController(
                            text: _time?.format(context) ?? ''),
                        () async {
                          final p = await showTimePicker(
                              context: context,
                              initialTime: _time ?? TimeOfDay.now());
                          if (p != null) setState(() => _time = p);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                customInputField('Short Description', _desc, maxLines: 3),
                const SizedBox(height: 18),
                customInputField(
                  'Estimated Repair Cost (BHD)',
                  _price,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter a value';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _damageValueToggle(),
                const SizedBox(height: 34),
                customFilledButton('Next  ››', _submit),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );

  Widget _damageValueToggle() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Expected Damage Value',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFF272727),
                borderRadius: BorderRadius.circular(32)),
            padding: const EdgeInsets.all(4),
            child: Row(children: [
              _opt('≤ 500 BHD', true),
              _opt('> 500 BHD', false),
            ]),
          ),
        ],
      );

  Widget _opt(String t, bool low) {
    final sel = _low == low;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _low = low),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Text(t,
              style: TextStyle(
                  color: sel ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  void _submit() {
    if (!_fKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DamageLocationScreen(
          claim: ClaimModel(
            vin: _vin.text.trim(),
            policy: _policy.text.trim(),
            location: _loc.text.trim(),
            description: _desc.text.trim(),
            date: _date ?? DateTime.now(),
            time: _time ?? TimeOfDay.now(),
            repairCost: double.parse(_price.text),
            expectedLow: _low,
          ),
        ),
      ),
    );
  }
}

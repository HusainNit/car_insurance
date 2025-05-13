import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants.dart';
import '../../../core/widgets/ui_helpers.dart';
import '../../claims/services/claim_service.dart';
import '../../claims/models/claim_model.dart';
import '../../claims/ui/photo_gallery_screen.dart';
import '../../../utils/cloudinary_helper.dart';

class DamageLocationScreen extends StatefulWidget {
  final ClaimModel claim;
  const DamageLocationScreen({super.key, required this.claim});

  @override
  State<DamageLocationScreen> createState() => _DamageLocationScreenState();
}

class _DamageLocationScreenState extends State<DamageLocationScreen> {
  final _picker = ImagePicker();
  final Map<int, List<dynamic>> _pics = {for (var i = 0; i < 8; i++) i: []};

  static const _spots = [
    Offset(0.22, 0.12),
    Offset(0.50, 0.08),
    Offset(0.78, 0.12),
    Offset(0.05, 0.45),
    Offset(0.95, 0.45),
    Offset(0.22, 0.85),
    Offset(0.50, 0.88),
    Offset(0.78, 0.85),
  ];
  static const _labels = [
    'front-left',
    'front-center',
    'front-right',
    'middle-left',
    'middle-right',
    'rear-left',
    'rear-center',
    'rear-right',
  ];

  bool get _ready => _pics.values.any((l) => l.isNotEmpty);
  static const _ratio = 411 / 736;
  static const _icon = 48.0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: customAppBar(context, 'Damage Location'),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: customFilledButton('Next  ››', _ready ? _finish : () {}),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),
            const Text('Tap each damaged area and take a photo.',
                style: TextStyle(fontSize: 15, color: Colors.white70)),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: _ratio,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child:
                            Image.asset('car_top_view.png', fit: BoxFit.contain),
                      ),
                      for (var i = 0; i < _spots.length; i++)
                        Align(
                          alignment: Alignment(
                              _spots[i].dx * 2 - 1, _spots[i].dy * 2 - 1),
                          child: SizedBox(width: _icon, height: _icon, child: _btn(i)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${_pics.values.expand((e) => e).length} photo(s) selected',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );

  Widget _btn(int i) {
    final filled = _pics[i]!.isNotEmpty;
    return GestureDetector(
      onTap: () => _capture(i),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? accentColor : const Color(0x66000000),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Icon(
          filled ? Icons.check : Icons.camera_alt,
          size: 26,
          color: filled ? Colors.black : accentColor,
        ),
      ),
    );
  }

  Future<void> _capture(int i) async {
    final shot =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (shot == null) return;
    _pics[i]!.add(kIsWeb ? await shot.readAsBytes() : File(shot.path));
    setState(() {});
  }

  Future<void> _finish() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => customLoadingSpinner(),
    );

    try {
      final damaged = _pics.entries
          .where((e) => e.value.isNotEmpty)
          .map((e) => _labels[e.key])
          .toList();

      final vehSnap = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('vin', isEqualTo: widget.claim.vin)
          .limit(1)
          .get();
      final value =
          (vehSnap.docs.first.data()['currentPrice'] as num).toDouble();
      final rate =
          widget.claim.repairCost > 0.4 * value ? 0.15 : 0.10;

      final claim = ClaimModel(
        vin: widget.claim.vin,
        policy: widget.claim.policy,
        location: widget.claim.location,
        description: widget.claim.description,
        date: widget.claim.date,
        time: widget.claim.time,
        repairCost: widget.claim.repairCost,
        damagedParts: damaged,
        consumptionRate: rate,
      );

      final doc = await ClaimService().createClaim(claim);

      for (final e in _pics.entries) {
        final spot = _labels[e.key];
        for (final src in e.value) {
          final url = await uploadToCloudinary(src, doc.id, spot);
          await ClaimService().addPhoto(docId: doc.id, spot: spot, url: url);
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PhotoGalleryScreen(claimDoc: doc)),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }
}

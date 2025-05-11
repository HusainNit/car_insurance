// lib/features/claims/ui/damage_location_screen.dart
import 'dart:io';

import 'package:car_insurance_app/core/widgets/ui_helpers.dart';
import 'package:car_insurance_app/core/constants.dart';
import 'package:car_insurance_app/utils/cloudinary_helper.dart';
import 'package:car_insurance_app/features/claims/services/claim_service.dart';
import 'package:car_insurance_app/features/claims/models/claim_model.dart';
import 'package:car_insurance_app/features/claims/ui/photo_gallery_screen.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DamageLocationScreen extends StatefulWidget {
  final ClaimModel claim;
  const DamageLocationScreen({super.key, required this.claim});

  @override
  State<DamageLocationScreen> createState() => _DamageLocationScreenState();
}

class _DamageLocationScreenState extends State<DamageLocationScreen> {
  final _picker = ImagePicker();
  final Map<int, List<dynamic>> _pics = {for (var i = 0; i < 8; i++) i: []};

  static const List<Offset> _spot = [
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
    'rear-right'
  ];

  bool get _ok => _pics.values.any((l) => l.isNotEmpty);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: customAppBar(context, 'Damage Location'),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: customFilledButton(
              'Next  ››',
              _ok ? _continue : () {},
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              'Tap each damaged area and take a photo.',
              style: TextStyle(fontSize: 15, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LayoutBuilder(builder: (_, cons) {
                final size = cons.biggest;
                final imgSide =
                    size.width < size.height ? size.width : size.height;
                return Center(
                  child: SizedBox(
                    width: imgSide,
                    height: imgSide,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset('car_top_view.png',
                              fit: BoxFit.contain),
                        ),
                        for (int i = 0; i < 8; i++)
                          Positioned(
                            left: _spot[i].dx * imgSide - 24,
                            top: _spot[i].dy * imgSide - 24,
                            child: _cam(i),
                          ),
                      ],
                    ),
                  ),
                );
              }),
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

  // rounded camera / check button
  Widget _cam(int i) {
    final filled = _pics[i]!.isNotEmpty;
    return GestureDetector(
      onTap: () => _pick(i),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? accentColor : const Color(0x66000000),
          border: Border.all(color: Colors.white24, width: 1.5),
          boxShadow:
              filled ? [BoxShadow(color: Colors.black26, blurRadius: 4)] : [],
        ),
        child: Icon(
          filled ? Icons.check : Icons.camera_alt,
          size: 26,
          color: filled ? Colors.black : accentColor,
        ),
      ),
    );
  }

  Future<void> _pick(int spot) async {
    final x =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (x == null) return;
    if (kIsWeb) {
      _pics[spot]!.add(await x.readAsBytes());
    } else {
      _pics[spot]!.add(File(x.path));
    }
    setState(() {});
  }

  Future<void> _continue() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => customLoadingSpinner(),
    );
    try {
      final doc = await ClaimService().createClaim(widget.claim);
      for (final e in _pics.entries) {
        final spot = _labels[e.key];
        for (final src in e.value) {
          final url = await uploadToCloudinary(src, doc.id, spot);
          await ClaimService()
              .addPhoto(docId: doc.id, spot: spot, url: url);
        }
      }
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoGalleryScreen(claimDoc: doc),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }
}

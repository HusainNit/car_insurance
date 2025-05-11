// lib/features/claims/ui/photo_gallery_screen.dart
import 'package:car_insurance_app/core/constants.dart';
import 'package:car_insurance_app/core/widgets/ui_helpers.dart';
import 'package:car_insurance_app/utils/cloudinary_helper.dart';
import 'package:car_insurance_app/features/claims/services/claim_service.dart';
import 'package:car_insurance_app/features/claims/ui/photo_inspection_screen.dart';
import 'package:car_insurance_app/features/claims/ui/submit_screen.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class PhotoGalleryScreen extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> claimDoc;
  const PhotoGalleryScreen({super.key, required this.claimDoc});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late final Stream<List<String>> _urls;

  @override
  void initState() {
    super.initState();
    _urls = widget.claimDoc
        .collection('photos')
        .orderBy('ts')
        .snapshots()
        .map((s) => s.docs.map((d) => d['url'] as String).toList());
  }

  Future<void> _addMore() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 80);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final url = await uploadToCloudinary(bytes, widget.claimDoc.id, 'extra');
    await ClaimService()
        .addPhoto(docId: widget.claimDoc.id, spot: 'extra', url: url);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: customAppBar(context, 'Capture Photos'),
        body: StreamBuilder<List<String>>(
          stream: _urls,
          builder: (_, snap) {
            if (!snap.hasData) return customLoadingSpinner();
            final urls = snap.data!;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Well Done, All Damage Photos Taken.',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text(
                    'Please take a moment to make sure you have photos of damaged parts.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.25,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: urls.length + 1,
                      itemBuilder: (_, i) {
                        if (i < urls.length) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                Image.network(urls[i], fit: BoxFit.cover),
                          );
                        }
                        return InkWell(
                          onTap: _addMore,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF242424),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.white12, width: 1),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add, size: 32, color: accentColor),
                                SizedBox(height: 6),
                                Text('Add More Photos',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.white70)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: customOutlinedButton(
                    'Inspect',
                    () async {
                      final snapshot = await widget.claimDoc
                          .collection('photos')
                          .orderBy('ts')
                          .get();
                      final urls =
                          snapshot.docs.map((d) => d['url'] as String).toList();
                      if (urls.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No photos to inspect')),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PhotoInspectionScreen(
                            imageUrls: urls,
                            claimDoc: widget.claimDoc,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: customFilledButton(
                    'Next  ››',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SubmitScreen(claimDoc: widget.claimDoc),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

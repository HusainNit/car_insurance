// lib/features/claims/ui/photo_inspection_screen.dart
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoInspectionScreen extends StatefulWidget {
  final List<String> imageUrls;
  final DocumentReference<Map<String, dynamic>> claimDoc;
  final int initialIndex;
  const PhotoInspectionScreen({
    super.key,
    required this.imageUrls,
    required this.claimDoc,
    this.initialIndex = 0,
  });

  @override
  State<PhotoInspectionScreen> createState() => _PhotoInspectionScreenState();
}

class _PhotoInspectionScreenState extends State<PhotoInspectionScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) =>
                  setState(() => _currentIndex = index),
              builder: (_, i) => PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(widget.imageUrls[i]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes:
                    PhotoViewHeroAttributes(tag: widget.imageUrls[i]),
              ),
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration:
                  const BoxDecoration(color: Colors.black),
            ),
            if (_currentIndex > 0)
              Positioned(
                left: 10,
                top: MediaQuery.of(context).size.height / 2 - 24,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut),
                ),
              ),
            if (_currentIndex < widget.imageUrls.length - 1)
              Positioned(
                right: 10,
                top: MediaQuery.of(context).size.height / 2 - 24,
                child: IconButton(
                  icon:
                      const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onPressed: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut),
                ),
              ),
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Photo ${_currentIndex + 1} of ${widget.imageUrls.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever,
                        color: Colors.redAccent),
                    onPressed: _deletePhoto,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Future<void> _deletePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    final url = widget.imageUrls[_currentIndex];
    await _deleteFromFirestore(url);
    setState(() {
      widget.imageUrls.removeAt(_currentIndex);
      if (_currentIndex > 0) _currentIndex--;
    });
    if (widget.imageUrls.isEmpty) Navigator.pop(context);
  }

  Future<void> _deleteFromFirestore(String url) async {
    final snap = await widget.claimDoc.collection('photos').get();
    for (final doc in snap.docs) {
      if (doc['url'] == url) {
        await doc.reference.delete();
        break;
      }
    }
  }
}

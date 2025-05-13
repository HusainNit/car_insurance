import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:car_insurance_app/core/constants.dart';

class VehiclePhotoPicker extends StatefulWidget {
  final Function(dynamic) onImageSelected;

  const VehiclePhotoPicker({
    Key? key,
    required this.onImageSelected,
  }) : super(key: key);

  @override
  _VehiclePhotoPickerState createState() => _VehiclePhotoPickerState();
}

class _VehiclePhotoPickerState extends State<VehiclePhotoPicker> {
  dynamic _imageFile;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _selectImage,
      child: Container(
        height: 200,
        width: double.infinity,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor, width: 2),
        ),
        child: _imageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_rounded,
                    size: 50,
                    color: accentColor,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Add Vehicle Photo',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: kIsWeb
                    ? Image.network(_imageUrl!)
                    : Image.file(
                        _imageFile,
                        fit: BoxFit.cover,
                      ),
              ),
      ),
    );
  }

  Future<void> _selectImage() async {
    final XFile? selectedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (selectedImage != null) {
      setState(() {
        if (kIsWeb) {
          _imageUrl = selectedImage.path;
          _imageFile = selectedImage;
        } else {
          _imageFile = File(selectedImage.path);
        }
        widget.onImageSelected(_imageFile);
      });
    }
  }
}

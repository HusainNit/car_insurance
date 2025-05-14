import 'dart:io';
import 'dart:math';
import 'package:car_insurance_app/core/constants.dart';
import 'package:car_insurance_app/core/widgets/ui_helpers.dart';
import 'package:car_insurance_app/core/widgets/main_scaffold.dart';
import 'package:car_insurance_app/features/registerVehicles/services/photo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_insurance_app/utils/cloudinary_helper.dart';

class VehicleRegistration extends StatefulWidget {
  const VehicleRegistration({super.key});

  @override
  State<VehicleRegistration> createState() => _VehicleRegistrationState();
}

class _VehicleRegistrationState extends State<VehicleRegistration> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _CustomerNameController = TextEditingController();
  final TextEditingController _VehicleModelController = TextEditingController();
  final TextEditingController _VehicleChassisNumberController =
      TextEditingController();
  final TextEditingController _VehicleRegistrationNumberController =
      TextEditingController();
  final TextEditingController _VehicleManufacturingYearController =
      TextEditingController();
  final TextEditingController _NumberOfPassengersController =
      TextEditingController();
  final TextEditingController _DriversAgeController = TextEditingController();
  final TextEditingController _CarPriceWhenNewController =
      TextEditingController();
  final TextEditingController _CarVINController = TextEditingController();
  final String _insuranceStatus = "Pending";
  String _insuranceType = "newInsurance";
  final String _ownerID = ""; // at login
  dynamic _imageFile;
  String? _photoUrl;

  double calculateDepreciatedPrice() {
    int initialPrice = int.parse(_CarPriceWhenNewController.text);
    int currentYear = DateTime.now().year;
    int manufacturingYear = int.parse(_VehicleManufacturingYearController.text);
    int yearsOld = currentYear - manufacturingYear;

    double annualDepreciationRate = 0.10; // 10% annual depreciation
    double currentValue = initialPrice.toDouble();

    // Apply compound depreciation for each year
    for (int i = 0; i < yearsOld; i++) {
      currentValue = currentValue * (1 - annualDepreciationRate);
    }

    return currentValue;
  }

  Future<bool> isVinUnique(String vin) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('vin', isEqualTo: vin)
        .get();
    return snapshot.docs.isEmpty;
  }

// Future<String?> validateFields() async {
//   // VIN validation
//   if (_CarVINController.text.isEmpty) {
//     return 'VIN is required';
//   }
//   if (!await isVinUnique(_CarVINController.text)) {
//     return 'This VIN already exists';
//   }

//   // Price validation
//   if (_CarPriceWhenNewController.text.isEmpty) {
//     return 'Price is required';
//   }
//   final price = int.tryParse(_CarPriceWhenNewController.text);
//   if (price == null || price <= 0) {
//     return 'Please enter a valid price';
//   }

//   // Year validation
//   if (_VehicleManufacturingYearController.text.isEmpty) {
//     return 'Manufacturing year is required';
//   }
//   final year = int.tryParse(_VehicleManufacturingYearController.text);
//   final currentYear = DateTime.now().year;
//   if (year == null || year < 1900 || year > currentYear + 1) {
//     return 'Please enter a valid manufacturing year';
//   }

//   // Age validation
//   if (_DriversAgeController.text.isEmpty) {
//     return 'Driver age is required';
//   }
//   final age = int.tryParse(_DriversAgeController.text);
//   if (age == null || age < 18 || age > 100) {
//     return 'Driver must be between 18 and 100 years old';
//   }

//   // Passengers validation
//   if (_NumberOfPassengersController.text.isEmpty) {
//     return 'Number of passengers is required';
//   }
//   final passengers = int.tryParse(_NumberOfPassengersController.text);
//   if (passengers == null || passengers <= 0 || passengers > 50) {
//     return 'Please enter a valid number of passengers';
//   }

//   // Other required fields
//   if (_CustomerNameController.text.isEmpty ||
//       _VehicleModelController.text.isEmpty ||
//       _VehicleChassisNumberController.text.isEmpty ||
//       _VehicleRegistrationNumberController.text.isEmpty) {
//     return 'All fields are required';
//   }

//   return null;
// }
  Future<void> createInsuranceRequest() async {
    try {
      // Generate a random insurance ID or let Firebase auto-generate it
      DocumentReference docRef =
          FirebaseFirestore.instance.collection("InsuranceReq").doc();

      // Get current date for policy dates
      DateTime now = DateTime.now();
      DateTime endDate = now.add(const Duration(days: 365)); // 1 year policy

      Map<String, dynamic> insuranceData = {
        "adminApproval": false,
        "coverageDetails": "",
        "insuranceOffers": [""],
        "paymentStatus": "Pending",
        "policyDetails": {
          "endDate": endDate.toIso8601String(),
          "policyNum": docRef.id,
          "startDate": now.toIso8601String(),
        },
        "userId": "_ownerID", // Replace with actual user ID
        "vehicleId": _CarVINController.text,
      };

      await docRef.set(insuranceData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error creating insurance request: ${e.toString()}")),
      );
    }
  }

  Future<void> sendDataToDB() async {
    try {
      // First upload the photo if available
      if (_imageFile != null) {
        if (kIsWeb) {
          _photoUrl = await uploadToCloudinary(await _imageFile.readAsBytes(),
              _CarVINController.text, 'vehicle');
        } else {
          _photoUrl = await uploadToCloudinary(
              _imageFile, _CarVINController.text, 'vehicle');
        }
      }
      DocumentReference docRef =
          FirebaseFirestore.instance.collection("vehicles").doc();

      Map<String, dynamic> Data = {
        "vin": _CarVINController.text,
        "chassisNum": _VehicleChassisNumberController.text,
        "currentPrice": calculateDepreciatedPrice(),
        "driverAge": _DriversAgeController.text,
        "insuranceStatus": _insuranceStatus,
        "insuranceType": _insuranceType,
        "manufacturingYear": _VehicleManufacturingYearController.text,
        "model": _VehicleModelController.text,
        "ownerId": "_ownerID",
        "passengersNum": _NumberOfPassengersController.text,
        "photos": _photoUrl ?? "", // Now includes the Cloudinary URL
        "priceWhenNew": _CarPriceWhenNewController.text,
        "registrationNum": _VehicleRegistrationNumberController.text,
      };

      await docRef.set(Data);
      await createInsuranceRequest();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vehicle registered successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  // String generateRandomCarVIN() {
  //   // Generate a random 17-character VIN
  //   String randomVIN = '';
  //   for (int i = 0; i < 17; i++) {
  //     randomVIN += String.fromCharCode(
  //         (Random().nextInt(26) + 65)); // Generate a random uppercase letter
  //   }
  //   return randomVIN;
  // }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      selectedIndex: 1,
      title: 'Vehicle Registration',
      body: Container(
        color: bgColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            key: _formKey,
            child: ListView(
              children: [
                VehiclePhotoPicker(
                  onImageSelected: (dynamic image) {
                    setState(() {
                      _imageFile = image;
                    });
                  },
                ),
                const SizedBox(height: 16),
                customInputField(
                  'Customer Name',
                  _CustomerNameController,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                customInputField(
                  'Driver\'s Age',
                  _DriversAgeController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Age is required';
                    final age = int.tryParse(value!);
                    if (age == null || age < 18 || age > 100) {
                      return 'Driver must be between 18 and 100 years old';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                customInputField(
                  'Car VIN',
                  _CarVINController,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'VIN is required';
                    isVinUnique(value!).then((isUnique) {
                      if (!isUnique) return 'This VIN already exists';
                    });
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                customInputField(
                  'Car Model',
                  _VehicleModelController,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Model is required' : null,
                ),
                const SizedBox(height: 16),
                customInputField(
                  'Car Price When New',
                  _CarPriceWhenNewController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Price is required';
                    final price = int.tryParse(value!);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                customInputField(
                  'Number of Passengers',
                  _NumberOfPassengersController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Number of passengers is required';
                    }
                    final passengers = int.tryParse(value!);
                    if (passengers == null ||
                        passengers <= 0 ||
                        passengers > 50) {
                      return 'Please enter a valid number of passengers (1-50)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                customInputField(
                  'Chassis Number',
                  _VehicleChassisNumberController,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Chassis number is required'
                      : null,
                ),
                const SizedBox(height: 16),
                customInputField(
                  'Registration Number',
                  _VehicleRegistrationNumberController,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Registration number is required'
                      : null,
                ),
                const SizedBox(height: 16),
                customInputField(
                  'Manufacturing Year',
                  _VehicleManufacturingYearController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Manufacturing year is required';
                    }
                    final year = int.tryParse(value!);
                    final currentYear = DateTime.now().year;
                    if (year == null || year < 1900 || year > currentYear + 1) {
                      return 'Please enter a valid year (1900-${currentYear + 1})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _insuranceType,
                    dropdownColor: const Color(0xFF282828),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Insurance Type',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'newInsurance',
                        child: Text('New Insurance',
                            style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem(
                        value: 'renewalInsurance',
                        child: Text('Renewal Insurance',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setState(() => _insuranceType = newValue!);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                customFilledButton(
                  'Register Vehicle',
                  () async {
                    if (_formKey.currentState!.validate()) {
                      sendDataToDB();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

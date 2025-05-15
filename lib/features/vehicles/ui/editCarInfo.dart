import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_insurance_app/core/constants.dart';
import 'package:car_insurance_app/core/widgets/ui_helpers.dart';

class EditVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;
  final String vehicleId;

  const EditVehicleScreen({
    Key? key,
    required this.vehicleData,
    required this.vehicleId,
  }) : super(key: key);

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController modelController;
  late TextEditingController registrationController;
  late TextEditingController chassisController;
  late TextEditingController manufacturingYearController;
  late TextEditingController currentPriceController;
  late TextEditingController priceWhenNewController;
  late TextEditingController passengersNumController;
  late TextEditingController driverAgeController;

  void initState() {
    super.initState();
    modelController =
        TextEditingController(text: widget.vehicleData['carModel']);
    registrationController = manufacturingYearController =
        TextEditingController(
            text: widget.vehicleData['manufacturingYear'].toString());
    currentPriceController = TextEditingController(
        text: widget.vehicleData['currentPrice'].toString());
    priceWhenNewController =
        TextEditingController(text: widget.vehicleData['priceWhenNew']);
    passengersNumController =
        TextEditingController(text: widget.vehicleData['passengersNum']);
    driverAgeController =
        TextEditingController(text: widget.vehicleData['driverAge']);
    chassisController =
        TextEditingController(text: widget.vehicleData['vin']);
  }

  @override
  void dispose() {
    modelController.dispose();
    registrationController.dispose();
    chassisController.dispose();
    manufacturingYearController.dispose();
    currentPriceController.dispose();
    priceWhenNewController.dispose();
    passengersNumController.dispose();
    driverAgeController.dispose();
    super.dispose();
  }

  Future<void> updateVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
              child: CircularProgressIndicator(color: accentColor));
        },
      );

      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .update({
        'carModel': modelController.text,
        'registrationNumber': registrationController.text,
        'manufacturingYear': int.parse(manufacturingYearController.text),
        'currentPrice': double.parse(currentPriceController.text),
        'priceWhenNew': priceWhenNewController.text,
        'passengersNum': passengersNumController.text,
        'driverAge': driverAgeController.text,
        'vin': chassisController.text,
        'updatedAt': DateTime.now(),
        'insured': true,
        
      });

      Navigator.pop(context); // Dismiss loading
      Navigator.pop(context); // Return to previous screen

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle updated successfully')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF282828),
        title:
            const Text('Edit Vehicle', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: accentColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: registrationController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: chassisController,
                decoration: const InputDecoration(
                  labelText: 'Chassis Number',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: manufacturingYearController,
                decoration: const InputDecoration(
                  labelText: 'Manufacturing Year',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: currentPriceController,
                decoration: const InputDecoration(
                  labelText: 'Current Price',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: priceWhenNewController,
                decoration: const InputDecoration(
                  labelText: 'Price When New',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passengersNumController,
                decoration: const InputDecoration(
                  labelText: 'Number of Passengers',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: driverAgeController,
                decoration: const InputDecoration(
                  labelText: 'Driver Age',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              customFilledButton(
                'Update Vehicle',
                updateVehicle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

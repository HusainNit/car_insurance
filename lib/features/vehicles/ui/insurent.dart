import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_insurance_app/core/constants.dart';
import 'package:car_insurance_app/core/widgets/ui_helpers.dart';
import 'dart:math';

class InsuranceRequestScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;
  final String vehicleId;

  const InsuranceRequestScreen({
    Key? key,
    required this.vehicleData,
    required this.vehicleId,
  }) : super(key: key);

  @override
  State<InsuranceRequestScreen> createState() => _InsuranceRequestScreenState();
}

class _InsuranceRequestScreenState extends State<InsuranceRequestScreen> {
  bool hadAccident = false;
  late double currentPrice;
  late double maxPrice;
  double insuranceAmount = 0;
  String insuranceStatus = 'Requested';
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    maxPrice = double.parse(widget.vehicleData['priceWhenNew'].toString());
    currentPrice = maxPrice;
    calculateInsurance();
  }

  void calculateInsurance() {
    final int manufacturingYear =
        int.parse(widget.vehicleData['manufacturingYear'].toString());
    int years = DateTime.now().year - manufacturingYear;
    double depreciation = pow(0.9, years).toDouble();
    insuranceAmount = (currentPrice * depreciation * 0.05);
    setState(() {});
  }

  Future<void> submitInsuranceRequest() async {
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
          .collection('InsuranceReq')
          .doc(widget.vehicleId)
          .set({
        'vehicleId': widget.vehicleId,
        'carModel': widget.vehicleData['carModel'],
        'registrationNumber': widget.vehicleData['registrationNumber'],
        'hadAccident': hadAccident,
        'currentValue': currentPrice,
        'insuranceCost': insuranceAmount,
        'insuranceStatus': insuranceStatus,
        'selectedOffer': '',
        'requestDate': DateTime.now(),
        "userId": user?.uid ?? "",
        'insuranceOffers': [],
        // 'policyDetails': {
        //   'policyNum': policyNumber,
        //   'startDate': DateTime.now().toString(),
        //   'endDate': DateTime.now().add(const Duration(days: 365)).toString(),
        // }
      });

      Navigator.pop(context);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insurance request submitted successfully'),
          backgroundColor: Color(0xFF282828),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Insurance Request',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: accentColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            infoCard([
              sectionTitle('Vehicle Information'),
              infoRow('Model:', widget.vehicleData['carModel']),
              infoRow(
                  'Registration:', widget.vehicleData['registrationNumber']),
              infoRow('Manufacturing Year:',
                  widget.vehicleData['manufacturingYear'].toString()),
            ]),
            const SizedBox(height: 24),
            Text(
              'Adjust Current Vehicle Value: \$${currentPrice.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Slider(
              value: currentPrice,
              min: maxPrice * 0.1, // Minimum 10% of max price
              max: maxPrice,
              divisions: 100,
              activeColor: accentColor,
              inactiveColor: Colors.grey,
              onChanged: (value) {
                setState(() {
                  currentPrice = value;
                  calculateInsurance();
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: hadAccident,
                  onChanged: (value) {
                    setState(() {
                      hadAccident = value ?? false;
                    });
                  },
                  fillColor: MaterialStateProperty.all(accentColor),
                ),
                const Text(
                  'Vehicle had previous accidents',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Insurance Amount:',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    '\$${insuranceAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: accentColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            customFilledButton(
              'Submit Insurance Request',
              submitInsuranceRequest,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

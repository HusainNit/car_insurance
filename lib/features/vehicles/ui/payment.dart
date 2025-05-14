import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_insurance_app/core/constants.dart';
import 'package:car_insurance_app/core/widgets/ui_helpers.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> insuranceData;

  const PaymentScreen({
    Key? key,
    required this.insuranceData,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int? selectedOfferIndex;

  Future<void> submitSelectedOffer() async {
    if (selectedOfferIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an offer')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
              child: CircularProgressIndicator(color: accentColor));
        },
      );

      final selectedOffer = (widget.insuranceData['insuranceOffers']
          as List)[selectedOfferIndex!];

      // Query using vehicleId
      final querySnapshot = await FirebaseFirestore.instance
          .collection('InsuranceReq')
          .where('vehicleId', isEqualTo: widget.insuranceData['vehicleId'])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'selectedOffer': selectedOffer,
          'insuranceStatus': 'Review',
        });
      }

      Navigator.pop(context); // Dismiss loading
      Navigator.pop(context); // Return to previous screen

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer selected successfully')),
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
        title: const Text('Select Insurance Offer',
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
              sectionTitle('Vehicle Details'),
              infoRow('Model:', widget.insuranceData['carModel']),
              infoRow(
                  'Registration:', widget.insuranceData['registrationNumber']),
              infoRow('Current Value:',
                  '\$${widget.insuranceData['currentValue']}'),
            ]),
            const SizedBox(height: 24),
            Text(
              'Available Insurance Offers',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.insuranceData['insuranceOffers'].length,
                itemBuilder: (context, index) {
                  return Card(
                    color: const Color(0xFF282828),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        widget.insuranceData['insuranceOffers'][index]
                            .toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Radio<int>(
                        value: index,
                        groupValue: selectedOfferIndex,
                        onChanged: (int? value) {
                          setState(() {
                            selectedOfferIndex = value;
                          });
                        },
                        fillColor: MaterialStateProperty.all(accentColor),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            customFilledButton(
              'Confirm Selection',
              submitSelectedOffer,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:car_insurance_app/features/vehicles/ui/insurent.dart';
import 'package:car_insurance_app/features/vehicles/ui/payment.dart';
import 'package:flutter/material.dart';
import 'package:car_insurance_app/core/constants.dart';
import 'package:car_insurance_app/core/widgets/ui_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> vehicleData;
  final String vehicleId;

  const VehicleDetailScreen({
    Key? key,
    required this.vehicleData,
    required this.vehicleId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF282828),
        title: const Text(
          'Vehicle Details',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: accentColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (vehicleData['photos'] != null &&
              vehicleData['photos'].toString().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                vehicleData['photos'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 24),
          infoCard([
            sectionTitle('Vehicle Information'),
            infoRow('Model:', vehicleData['carModel'] ?? 'N/A'),
            infoRow(
                'Registration:', vehicleData['registrationNumber'] ?? 'N/A'),
            infoRow('Manufacturing Year:',
                vehicleData['manufacturingYear'].toString() ?? 'N/A'),
            infoRow(
                'Price When New:', '\$${vehicleData['priceWhenNew'] ?? 'N/A'}'),
            infoRow('insurance type:',
                vehicleData['insured'] ? "renewal" : "new insurance"),
            infoRow('Passengers:', vehicleData['passengersNum'] ?? 'N/A'),
            infoRow('Driver Age:', vehicleData['driverAge'] ?? 'N/A'),
          ]),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('InsuranceReq')
                .where('vehicleId', isEqualTo: vehicleId)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final insuranceData = snapshot.data!.docs.isEmpty
                  ? null
                  : snapshot.data?.docs.first.data() as Map<String, dynamic>?;

              if (insuranceData == null) {
                return customFilledButton(
                  'Request Insurance',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InsuranceRequestScreen(
                        vehicleData: vehicleData,
                        vehicleId: vehicleData['vin'],
                      ),
                    ),
                  ),
                );
              }

              // if (insuranceData['selectedOffer'] != '') {
              //   return Container(
              //     padding: const EdgeInsets.all(16),
              //     decoration: BoxDecoration(
              //       color: const Color(0xFF282828),
              //       borderRadius: BorderRadius.circular(8),
              //       border: Border.all(color: accentColor),
              //     ),
              //     child: const Column(
              //       children: [
              //         Icon(Icons.check_circle, color: accentColor, size: 48),
              //         SizedBox(height: 12),
              //         Text(
              //           'Thank you for using our service!',
              //           style: TextStyle(
              //               color: Colors.white,
              //               fontSize: 18,
              //               fontWeight: FontWeight.bold),
              //           textAlign: TextAlign.center,
              //         ),
              //       ],
              //     ),
              //   );
              // }

              if (insuranceData['insuranceStatus'] == 'Offering') {
                return customFilledButton(
                  'View Insurance Offers',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        insuranceData: insuranceData,
                      ),
                    ),
                  ),
                );
              }
              if (insuranceData['insuranceStatus'] == 'Paid') {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle, color: accentColor, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Thank you for using our service!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (insuranceData['insuranceStatus'] == 'Unpaid') {
                return customFilledButton(
                  'Make Payment',
                  () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('InsuranceReq')
                          .where('vehicleId', isEqualTo: vehicleId)
                          .get()
                          .then((snapshot) {
                        if (snapshot.docs.isNotEmpty) {
                          snapshot.docs.first.reference
                              .update({'insuranceStatus': 'Paid'});
                        }
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Payment completed successfully')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Error processing payment: ${e.toString()}')),
                      );
                    }
                  },
                );
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Waiting for Insurance Approval',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

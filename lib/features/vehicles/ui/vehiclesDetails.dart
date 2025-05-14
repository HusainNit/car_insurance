import 'package:flutter/material.dart';
import 'package:car_insurance_app/core/constants.dart';
import 'package:car_insurance_app/core/widgets/ui_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> vehicleData;
  final String vehicleId;

  const VehicleDetailScreen({
    super.key,
    required this.vehicleData,
    required this.vehicleId,
  });

  void _selectOffer(BuildContext context, dynamic policyData, int index) async {
    try {
      await FirebaseFirestore.instance
          .collection('InsuranceReq')
          .doc(policyData['policyDetails']['policyNum'])
          .update({
        'selectedOffer': policyData['insuranceOffers'][index],
        'paymentStatus': 'Pending'
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer selected, proceed to payment')),
      );
    } catch (e) {
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
        title: Text(
          'Vehicle Details',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: accentColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('InsuranceReq')
            .where('vehicleId', isEqualTo: vehicleId)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: accentColor));
          }

          final policyData = snapshot.data!.docs.isNotEmpty
              ? snapshot.data!.docs.first.data() as Map<String, dynamic>
              : {};

          return ListView(
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
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insurance Status: ${policyData['insuranceStatus'] ?? 'New Request'}',
                      style: TextStyle(
                          color: accentColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    if (policyData['insuranceOffers']?.isNotEmpty ?? false)
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            'Available Offers:',
                            style: TextStyle(color: Colors.white70),
                          ),
                          ...List.generate(
                            (policyData['insuranceOffers'] as List).length,
                            (index) => ListTile(
                              dense: true,
                              title: Text(
                                policyData['insuranceOffers'][index].toString(),
                                style: TextStyle(color: Colors.white),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.check_circle_outline,
                                    color: accentColor),
                                onPressed: () =>
                                    _selectOffer(context, policyData, index),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              infoCard([
                sectionTitle('Vehicle Information'),
                infoRow('Model:', vehicleData['model'] ?? 'N/A'),
                infoRow(
                    'Registration:', vehicleData['registrationNum'] ?? 'N/A'),
                infoRow('Chassis Number:', vehicleData['chassisNum'] ?? 'N/A'),
                infoRow('Manufacturing Year:',
                    vehicleData['manufacturingYear'] ?? 'N/A'),
                infoRow('Current Price:',
                    '\$${vehicleData['currentPrice']?.toString() ?? 'N/A'}'),
              ]),
              const SizedBox(height: 16),
              infoCard([
                sectionTitle('Insurance Status'),
                infoRow('Admin Approval:',
                    policyData['adminApproval']?.toString() ?? 'N/A'),
                infoRow(
                    'Payment Status:', policyData['paymentStatus'] ?? 'N/A'),
              ]),
              const SizedBox(height: 16),
              infoCard([
                sectionTitle('Policy Details'),
                infoRow('Policy Number:',
                    policyData['policyDetails']?['policyNum'] ?? 'N/A'),
                infoRow('Start Date:',
                    policyData['policyDetails']?['startDate'] ?? 'N/A'),
                infoRow('End Date:',
                    policyData['policyDetails']?['endDate'] ?? 'N/A'),
              ]),
              const SizedBox(height: 16),
              if ((policyData['insuranceOffers'] ?? []).isNotEmpty)
                infoCard([
                  sectionTitle('Insurance Offers'),
                  ...List.generate(
                    (policyData['insuranceOffers'] as List).length,
                    (index) => infoRow(
                      'Offers :',
                      policyData['insuranceOffers'][index].toString(),
                    ),
                  ),
                ]),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (policyData['adminApproval'] != true)
                    Expanded(
                      child: customFilledButton(
                        'Request Insurance',
                        () async {
                          try {
                            await FirebaseFirestore.instance
                                .collection('InsuranceReq')
                                .doc(policyData['policyDetails']['policyNum'])
                                .update({
                              'insuranceStatus': 'Requested',
                              'adminApproval': false
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Insurance request sent to administrator')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        },
                      ),
                    ),
                  const SizedBox(width: 16),
                  if (policyData['paymentStatus'] == 'Pending')
                    Expanded(
                      child: customFilledButton(
                        'Make Payment',
                        () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: const Color(0xFF282828),
                                title: const Text(
                                  'Payment Confirmation',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'Would you like to proceed with payment?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('Cancel',
                                        style: TextStyle(color: Colors.grey)),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                  TextButton(
                                    child: const Text('Process Payment',
                                        style: TextStyle(color: accentColor)),
                                    onPressed: () async {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('InsuranceReq')
                                            .doc(policyData['policyDetails']
                                                ['policyNum'])
                                            .update({
                                          'paymentStatus': 'Processing',
                                          'adminApproval': false
                                        });

                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Payment processing and request sent to administrator'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      } catch (e) {
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error: ${e.toString()}')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

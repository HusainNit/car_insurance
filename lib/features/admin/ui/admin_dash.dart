import 'package:car_insurance_app/core/constants.dart';
import 'package:car_insurance_app/features/auth/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String adminName = "Admin";
  int pendingClaims = 0;
  int totalUsers = 0;
  int activePolicies = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Get admin details
      final User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot adminDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (adminDoc.exists && adminDoc.get('userType') == 'admin') {
          // If admin name is stored, use it. Otherwise use email
          if (adminDoc.data() is Map && (adminDoc.data() as Map).containsKey('name')) {
            setState(() {
              adminName = adminDoc.get('name');
            });
          } else {
            setState(() {
              adminName = user.email?.split('@')[0] ?? "Admin";
            });
          }
        }
      }

      // Get pending claims count
      QuerySnapshot claimsSnapshot = await _firestore
          .collection('claims')
          .where('status', isEqualTo: 'pending')
          .get();
      
      // Get total users count (only customers)
      QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'customer')
          .get();
      
      // Get active policies count
      QuerySnapshot policiesSnapshot = await _firestore
          .collection('policies')
          .where('status', isEqualTo: 'active')
          .get();

      setState(() {
        pendingClaims = claimsSnapshot.docs.length;
        totalUsers = usersSnapshot.docs.length;
        activePolicies = policiesSnapshot.docs.length;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading dashboard data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => LoginPage())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Admin Dashboard", 
          style: TextStyle(
            color:accentColor,
            letterSpacing: .5,
            fontSize: 24
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin welcome section
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor:accentColor,
                          child: Icon(Icons.admin_panel_settings, size: 35, color: Colors.black),
                        ),
                        SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back,",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              adminName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 25),
                  
                  // Stats grid
                  Text(
                    "Overview",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 15),
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        "Pending Claims",
                        pendingClaims.toString(),
                        Icons.report_problem,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        "Total Users",
                        totalUsers.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        "Active Policies",
                        activePolicies.toString(),
                        Icons.policy,
                        Colors.green,
                      ),
                      _buildStatCard(
                        "Revenue",
                        "\$12,450",
                        Icons.attach_money,
                        Colors.purple,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Quick actions
                  Text(
                    "Quick Actions",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 15),
                  
                  _buildActionCard(
                    "Manage Users",
                    "View and manage customer accounts",
                    Icons.people_outline,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                  ),
                  
                  SizedBox(height: 15),
                  
                  _buildActionCard(
                    "Review Claims",
                    "Process pending insurance claims",
                    Icons.assignment_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                  ),
                  
                  SizedBox(height: 15),
                  
                  _buildActionCard(
                    "Insurance Plans",
                    "Manage available insurance plans",
                    Icons.description_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                  ),
                  
                  SizedBox(height: 15),
                  
                  _buildActionCard(
                    "Analytics",
                    "View detailed business analytics",
                    Icons.analytics_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:accentColor,
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// Insurance Quotations page
class InsuranceQuotationsPage extends StatefulWidget {
  const InsuranceQuotationsPage({super.key});

  @override
  State<InsuranceQuotationsPage> createState() => _InsuranceQuotationsPageState();
}

class _InsuranceQuotationsPageState extends State<InsuranceQuotationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> insuranceRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsuranceRequests();
  }

  Future<void> _loadInsuranceRequests() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('InsuranceReq')
          .where('adminApproval', isEqualTo: false)
          .get();

      setState(() {
        insuranceRequests = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading insurance requests: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Calculate quotation based on car price, depreciation, and offer tiers
  Map<String, dynamic> _calculateQuotation(Map<String, dynamic> carData) {
    double carPrice = double.parse(carData['carPrice'].toString());
    int carYear = int.parse(carData['carYear'].toString());
    int currentYear = DateTime.now().year;
    int ageYears = currentYear - carYear;
    
    // Calculate depreciation (5% per year, max 50%)
    double depreciationRate = ageYears * 0.05;
    if (depreciationRate > 0.5) depreciationRate = 0.5;
    
    double currentValue = carPrice * (1 - depreciationRate);
    
    // Calculate premium tiers - standard values can be adjusted
    double basicPremium = currentValue * 0.03;
    double standardPremium = currentValue * 0.045;
    double premiumTier = currentValue * 0.06;
    
    // Coverage values
    double basicCoverage = currentValue * 0.7;
    double standardCoverage = currentValue * 0.85;
    double premiumCoverage = currentValue;
    
    return {
      'basic': {
        'name': 'Basic Coverage',
        'premium': basicPremium.round(),
        'coverage': basicCoverage.round(),
        'deductible': (basicPremium * 0.2).round(),
        'details': ['Third-party liability', 'Basic collision coverage', 'Fire and theft protection']
      },
      'standard': {
        'name': 'Standard Coverage',
        'premium': standardPremium.round(),
        'coverage': standardCoverage.round(),
        'deductible': (standardPremium * 0.15).round(),
        'details': ['All Basic coverage', 'Comprehensive protection', 'Roadside assistance', 'Rental car coverage']
      },
      'premium': {
        'name': 'Premium Coverage',
        'premium': premiumTier.round(),
        'coverage': premiumCoverage.round(),
        'deductible': (premiumTier * 0.1).round(),
        'details': ['All Standard coverage', 'Full replacement value', 'Zero depreciation', 'Personal accident cover', 'No-claims bonus protection']
      }
    };
  }

  Future<void> _sendQuotation(String requestId, Map<String, dynamic> quotationData) async {
    try {
      // Update the request with quotation data
      await _firestore.collection('insurance_requests').doc(requestId).update({
        'status': 'quoted',
        'quotationData': quotationData,
        'quotationDate': FieldValue.serverTimestamp(),
      });

      // Refresh the list
      await _loadInsuranceRequests();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quotation sent successfully!'))
      );
    } catch (e) {
      print("Error sending quotation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending quotation. Please try again.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Insurance Quotations",
          style: TextStyle(
            color: accentColor,
            letterSpacing: .5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadInsuranceRequests,
          ),
        ],
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : insuranceRequests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 60, color: Colors.white60),
                  SizedBox(height: 16),
                  Text(
                    "No pending insurance requests",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: insuranceRequests.length,
              padding: EdgeInsets.all(16.0),
              itemBuilder: (context, index) {
                var request = insuranceRequests[index].data() as Map<String, dynamic>;
                var carData = request['carDetails'] as Map<String, dynamic>;
                var userData = request['userDetails'] as Map<String, dynamic>;
                
                // Format the request date
                String requestDate = "N/A";
                if (request['requestDate'] != null) {
                  Timestamp timestamp = request['requestDate'] as Timestamp;
                  requestDate = DateFormat('MMM dd, yyyy').format(timestamp.toDate());
                }
                
                return Card(
                  margin: EdgeInsets.only(bottom: 16.0),
                  elevation: 2.0,
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    leading: CircleAvatar(
                      backgroundColor: accentColor,
                      child: Icon(Icons.directions_car, color: Colors.black),
                    ),
                    title: Text(
                      "${carData['carMake']} ${carData['carModel']} (${carData['carYear']})",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text("Requested by: ${userData['name']}"),
                        Text("Date: $requestDate"),
                      ],
                    ),
                    children: [
                      // Car Details Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Car Details:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildDetailRow("Make", carData['carMake']),
                          _buildDetailRow("Model", carData['carModel']),
                          _buildDetailRow("Year", carData['carYear']),
                          _buildDetailRow("License Plate", carData['licensePlate']),
                          _buildDetailRow("Purchase Price", "\$${carData['carPrice']}"),
                          SizedBox(height: 16),
                          
                          // User Details Section
                          Text(
                            "User Details:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildDetailRow("Name", userData['name']),
                          _buildDetailRow("Email", userData['email']),
                          _buildDetailRow("Phone", userData['phone']),
                          _buildDetailRow("Driver's License", userData['driversLicense']),
                          SizedBox(height: 16),
                          
                          // Generate Quote Button
                          Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              icon: Icon(Icons.calculate),
                              label: Text("Generate Quotation"),
                              onPressed: () {
                                Map<String, dynamic> quotationData = _calculateQuotation(carData);
                                showDialog(
                                  context: context,
                                  builder: (context) => QuotationDialog(
                                    carData: carData,
                                    quotationData: quotationData,
                                    onSend: () => _sendQuotation(
                                      insuranceRequests[index].id,
                                      quotationData,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "N/A",
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuotationDialog extends StatelessWidget {
  final Map<String, dynamic> carData;
  final Map<String, dynamic> quotationData;
  final VoidCallback onSend;

  const QuotationDialog({
    super.key,
    required this.carData,
    required this.quotationData,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  "Insurance Quotation",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  "${carData['carMake']} ${carData['carModel']} (${carData['carYear']})",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              // Basic tier card
              _buildQuotationTierCard(
                context,
                quotationData['basic'],
                Colors.blue.shade100,
                Colors.blue,
              ),
              SizedBox(height: 16),
              
              // Standard tier card  
              _buildQuotationTierCard(
                context,
                quotationData['standard'],
                Colors.green.shade100,
                Colors.green,
              ),
              SizedBox(height: 16),
              
              // Premium tier card
              _buildQuotationTierCard(
                context,
                quotationData['premium'],
                Colors.purple.shade100,
                Colors.purple,
              ),
              SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel"),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                    ),
                    onPressed: () {
                      onSend();
                      Navigator.pop(context);
                    },
                    child: Text("Send Quotation"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotationTierCard(
    BuildContext context,
    Map<String, dynamic> tierData,
    Color bgColor,
    Color accentColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: accentColor),
                SizedBox(width: 8),
                Text(
                  tierData['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            _buildQuotationDetailRow("Annual Premium", "\$${tierData['premium']}"),
            _buildQuotationDetailRow("Coverage Amount", "\$${tierData['coverage']}"),
            _buildQuotationDetailRow("Deductible", "\$${tierData['deductible']}"),
            
            SizedBox(height: 12),
            Text(
              "Coverage Details:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (tierData['details'] as List).map<Widget>((detail) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(detail)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotationDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Claims Review Page
class ClaimsReviewPage extends StatefulWidget {
  const ClaimsReviewPage({super.key});

  @override
  State<ClaimsReviewPage> createState() => _ClaimsReviewPageState();
}

class _ClaimsReviewPageState extends State<ClaimsReviewPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> claims = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('claims')
          .where('status', isEqualTo: 'Pending')
          .orderBy('submissionDate', descending: true)
          .get();

      setState(() {
        claims = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading claims: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Claims Review",
          style: TextStyle(
            color: accentColor,
            letterSpacing: .5,
          ),
        ),
      ),
      body: Center(
        child: Text("Claims Review Page - Coming Soon"),
      ),
    );
  }
}

// User Management Page
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "User Management",
          style: TextStyle(
            color: accentColor,
            letterSpacing: .5,
          ),
        ),
      ),
      body: Center(
        child: Text("User Management Page - Coming Soon"),
      ),
    );
  }
}

// Insurance Plans Page
class InsurancePlansPage extends StatefulWidget {
  const InsurancePlansPage({super.key});

  @override
  State<InsurancePlansPage> createState() => _InsurancePlansPageState();
}

class _InsurancePlansPageState extends State<InsurancePlansPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Insurance Plans",
          style: TextStyle(
            color: accentColor,
            letterSpacing: .5,
          ),
        ),
      ),
      body: Center(
        child: Text("Insurance Plans Page - Coming Soon"),
      ),
    );
  }
}

// Analytics Page
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Analytics",
          style: TextStyle(
            color: accentColor,
            letterSpacing: .5,
          ),
        ),
      ),
      body: Center(
        child: Text("Analytics Page - Coming Soon"),
      ),
    );
  }
}
import 'package:car_insurance_app/core/constants.dart';
import 'package:car_insurance_app/core/widgets/ui_helpers.dart';
import 'package:car_insurance_app/features/auth/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_insurance_app/features/admin/ui/review_claims_screen.dart';


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
  int IssuedPolicies = 0;
  int pendingQuotations = 0;
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
          .where('status', isEqualTo: 'Pending')
          .get();
      
      // Get total users count (only customers)
      QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'customer')
          .get();
      
      // Get active policies count
      QuerySnapshot policiesSnapshot = await _firestore
          .collection('InsuranceReq')
          .where('insuranceStatus', isEqualTo: 'Approved')
          .get();

      // Get pending quotations count
      QuerySnapshot quotationsSnapshot = await _firestore
          .collection('InsuranceReq')
          .where('insuranceStatus', isEqualTo: 'Requested')
          .get();

     
       

      setState(() {
        pendingClaims = claimsSnapshot.docs.length;
        totalUsers = usersSnapshot.docs.length;
        IssuedPolicies = policiesSnapshot.docs.length;
        pendingQuotations = quotationsSnapshot.docs.length;
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
            color: accentColor,
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
                          backgroundColor: accentColor,
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
                        "Pending Quotations",
                        pendingQuotations.toString(),
                        Icons.request_quote,
                        Colors.red,
                      ),
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
                        "Issued Policies",
                        IssuedPolicies.toString(),
                        Icons.policy,
                        Colors.green,
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
                    "Insurance Quotations",
                    "Review and process insurance requests",
                    Icons.calculate_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => InsuranceQuotationsPage()),
                      );
                    },
                  ),
                  
                  SizedBox(height: 15),
                  
                  _buildActionCard(
                    "Review Offers ",
                    "Process pending insurance offers ",
                    Icons.assignment_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ReviewOffersPage()),
                      );
                    },
                  ),
                  
                  SizedBox(height: 15),
                  
                  _buildActionCard(
                    "Approve Insurance Policy",
                    "Complete Insurance Request and Approve Inusrance Policy",
                    Icons.people_outline,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => InusrancePolicy()),
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
                          MaterialPageRoute(
                              builder: (context) => ReviewClaimsScreen()),
                        );
                      },
                    ),
                  SizedBox(height: 15),
                  
                 
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
          backgroundColor: accentColor,
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
  List<DocumentSnapshot> vehicleDetails = [];
  bool isLoading = true;
 


  @override
  void initState() {
    super.initState();
    _loadInsuranceRequests();
     _vehicleDetails();
  }

  Future<void> _loadInsuranceRequests() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('InsuranceReq')
          .where('insuranceStatus', isEqualTo: "Requested")
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
  Future<void> _vehicleDetails() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('vehicles')
          .get();

      setState(() {
        vehicleDetails = snapshot.docs;
      
      });
    } catch (e) {
      print(e);
      
    }
  }



 offer(double amount) {

    double luxury = amount* 1.3;
    double premium = amount*1.1;  
    
    String offers = " Luxury Option: ${luxury.toStringAsFixed(1)}  \n Premium Option: ${premium.toStringAsFixed(1)}  \n Standard Option: ${amount.toStringAsFixed(1)}";

    return offers; 

 }

   offerCustomer(String docId ,double amount ) async {
    final DocumentReference docRef;
  docRef =
      FirebaseFirestore.instance.collection("InsuranceReq").doc(docId);
    try {
       docRef.update({
      "insuranceStatus": "Offering",
      "insuranceOffers" : ["Luxury Option:  ${(amount*1.3).toStringAsFixed(1)}","Premium Option:  ${(amount*1.1).toStringAsFixed(1)}","Standard Option:  ${(amount*1).toStringAsFixed(1)}"]
    }).whenComplete((){

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Offer Submitted ! " , style: TextStyle(color: Colors.white),), backgroundColor: Colors.greenAccent,)  );

    });

      
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error Encounter" , style: TextStyle(color: Colors.white),), backgroundColor: Colors.redAccent,)  );
        print("$e");
      
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
                    title: Text("${insuranceRequests[index]['carModel']} - ${insuranceRequests[index]['registrationNumber']}",
                      
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    children: [
                      // Car Details Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Inusurance Cost:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          
                          ),
                      
                        Text(" ${insuranceRequests[index]['insuranceCost']}BD"),
                        Text(""),
                        Text("Insurance Offers: ", 
                              style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,)),

                        Text(offer(insuranceRequests[index]['insuranceCost'])),
                        Text(""),


                          

                          customFilledButton("Offer", (){


                            offerCustomer(insuranceRequests[index].id, insuranceRequests[index]['insuranceCost']);
                            
                            _loadInsuranceRequests();


                          })
                         
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




//  Review Offers Page
class ReviewOffersPage extends StatefulWidget {
  const ReviewOffersPage({super.key});

  @override
  State<ReviewOffersPage> createState() => _ReviewOffersPageState();
}

class _ReviewOffersPageState extends State<ReviewOffersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> OffersReview = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfferReviews();
  }

  
  Future<void> _loadOfferReviews() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('InsuranceReq')
          .where('insuranceStatus', isEqualTo: "Review")
          .get();

      setState(() {
        OffersReview = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      print(" $e");
      setState(() {
        isLoading = false;
      });
    }
  }


 unPaid(String docId) async {
    final DocumentReference docRef;
  docRef =
      FirebaseFirestore.instance.collection("InsuranceReq").doc(docId);
    try {
       docRef.update({
      "insuranceStatus": "Unpaid"
    }).whenComplete((){

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Requested ! " , style: TextStyle(color: Colors.white),), backgroundColor: Colors.greenAccent,)  );

    });

      
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error Encounter" , style: TextStyle(color: Colors.white),), backgroundColor: Colors.redAccent,)  );
        print("$e");
      
    }
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Review Offers",
          style: TextStyle(
            color: accentColor,
            letterSpacing: .5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadOfferReviews,
          ),
        ],
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : OffersReview.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 60, color: Colors.white60),
                  SizedBox(height: 16),
                  Text(
                    "No pending Offer Reviews",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: OffersReview.length,
              padding: EdgeInsets.all(16.0),
              itemBuilder: (context, index) {
              
                
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
                    title: Text("${OffersReview[index]['carModel']} - ${OffersReview[index]['registrationNumber']}",
                      
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    children: [
                      // Car Details Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Inusurance Cost:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          
                          ),
                      
                        Text(" ${OffersReview[index]['insuranceCost']}BD"),
                        Text(""),
                        Text("Offer Selected: ", 
                              style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,)),

                        Text(" ${OffersReview[index]['selectedOffer']}"),
                        Text(""),


                          

                          customFilledButton("Request Payment", (){
                            unPaid(OffersReview[index].id);
                            _loadOfferReviews();
                            


                          })
                         
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// User Management Page
class InusrancePolicy extends StatefulWidget {
  const InusrancePolicy({super.key});

  @override
  State<InusrancePolicy> createState() => _InusrancePolicyState();
}

class _InusrancePolicyState extends State<InusrancePolicy> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> PaidReview = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaidReviews();
  }

  
  Future<void> _loadPaidReviews() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('InsuranceReq')
          .where('insuranceStatus', isEqualTo: "Paid")
          .get();

      setState(() {
        PaidReview = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      print(" $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  approvePolicy(String docId) async {
    final DocumentReference docRef;
  docRef =
      FirebaseFirestore.instance.collection("InsuranceReq").doc(docId);
    try {
       docRef.update({
      "insuranceStatus": "Approved",
      'policyDetails': {
          'policyNum': docId,
          'startDate': DateTime.now().toString(),
          'endDate': DateTime.now().add(const Duration(days: 365)).toString(),
        }
    }).whenComplete( (){

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Policy Approved ! " , style: TextStyle(color: Colors.white),), backgroundColor: Colors.greenAccent,)  );

    });

    
    

      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error Encounter" , style: TextStyle(color: Colors.white),), backgroundColor: Colors.redAccent,)  );
      print("$e");
     
      
    }
  }

  



   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Insurance Policy Review",
          style: TextStyle(
            color: accentColor,
            letterSpacing: .5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPaidReviews,
          ),
        ],
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : PaidReview.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 60, color: Colors.white60),
                  SizedBox(height: 16),
                  Text(
                    "No pending Paid Reviews",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: PaidReview.length,
              padding: EdgeInsets.all(16.0),
              itemBuilder: (context, index) {
              
                
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
                    title: Text("${PaidReview[index]['carModel']} - ${PaidReview[index]['registrationNumber']}",
                      
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    children: [
                      // Car Details Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                        Text("Offer Selected: ", 
                              style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,)),

                        Text(" ${PaidReview[index]['selectedOffer']}"),
                          
                        Text(""),
                        Text(" Payment Completed", 
                              style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,)),
                        Text(""),

                        
                          

                          customFilledButton("Approve Policy", (){

                            approvePolicy(PaidReview[index].id);
                            _loadPaidReviews();
                          



                          })
                         
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}


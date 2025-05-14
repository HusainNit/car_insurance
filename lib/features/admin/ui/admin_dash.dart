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
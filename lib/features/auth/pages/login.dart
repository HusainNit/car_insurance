
import 'package:car_insurance_app/core/constants.dart';
import 'package:car_insurance_app/features/admin/ui/admin_dash.dart';
import 'package:car_insurance_app/features/auth/pages/signup.dart';
import 'package:car_insurance_app/features/vehicles/ui/vehicles_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login with email and password
  Future<void> loginWithEmailAndPassword() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Validate inputs
      if (email.text.isEmpty || pass.text.isEmpty) {
        throw FirebaseAuthException(
          code: 'empty-fields',
          message: 'Please fill in all fields',
        );
      }

      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text,
      );
      
      // Get user data from Firestore to determine user type
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }
      
      // Check user type and navigate accordingly
      String userType = userDoc.get('userType') as String;
      
      if (mounted) {
        if (userType == 'admin') {
          // Navigate to admin dashboard
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => AdminDashboard())
          );
        } else {
          // Navigate to customer home page
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => VehiclesScreen())
          );
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Login", 
          style: TextStyle(
            color:accentColor, 
            letterSpacing: .5, 
            fontSize: 30
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 25),
              ListTile(
                title: Text(
                  "Email", 
                  style: TextStyle(
                    color: Colors.white,
                    letterSpacing: 1, 
                    fontSize: 16, 
                    fontWeight: FontWeight.w700
                  )
                ), 
                leading: Icon(Icons.local_post_office_outlined),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Enter your email address",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  "Password", 
                  style: TextStyle(
                    color: Colors.white, 
                    letterSpacing: 1, 
                    fontSize: 16, 
                    fontWeight: FontWeight.w700
                  )
                ), 
                leading: Icon(Icons.lock),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: pass,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Enter your password",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              
              // Error message display
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              
              ListTile(
                title: Text("Don't have an Account? Signup"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SignupPage())
                  );
                },
              ),
              
              Container(
                height: 55,
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginWithEmailAndPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)
                    )
                  ),
                  child: isLoading 
                    ? CircularProgressIndicator(color: Colors.black)
                    : Text(
                        "Login", 
                        style: TextStyle(
                          letterSpacing: 1, 
                          fontSize: 18, 
                          fontWeight: FontWeight.w700
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
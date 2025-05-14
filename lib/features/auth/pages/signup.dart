import 'package:car_insurance_app/core/constants.dart';
import 'package:car_insurance_app/features/admin/ui/admin_dash.dart';
import 'package:car_insurance_app/features/auth/pages/login.dart';
import 'package:car_insurance_app/features/vehicles/ui/vehicles_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// Move controllers inside the state class to avoid global variables
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Controllers
  final TextEditingController email = TextEditingController();
  final TextEditingController pass = TextEditingController();
  final TextEditingController Cpass = TextEditingController();
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // UI states
  String selected = "";
  Color admin = Colors.white;
  Color Customer = Colors.white;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    // Clean up controllers when the widget is removed
    email.dispose();
    pass.dispose();
    Cpass.dispose();
    super.dispose();
  }

  // User registration method
  Future<void> signUp() async {
    // Input validation
    if (email.text.isEmpty || pass.text.isEmpty || Cpass.text.isEmpty) {
      setState(() {
        errorMessage = "Please fill in all fields";
      });
      return;
    }

    if (selected.isEmpty) {
      setState(() {
        errorMessage = "Please select a role (Admin or Customer)";
      });
      return;
    }

    if (pass.text != Cpass.text) {
      setState(() {
        errorMessage = "Passwords don't match";
      });
      return;
    }

    // Password strength validation
    if (pass.text.length < 6) {
      setState(() {
        errorMessage = "Password should be at least 6 characters";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text,
      );

      // Store user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email.text.trim(),
        'userType': selected.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate based on user role
      if (mounted) {
        if (selected == "Admin") {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) =>AdminDashboard())
          );
        } else {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) =>VehiclesScreen())
          );
        }
      }
    }   catch (e) {
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
          "Sign Up", 
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
                    hintText: "Create strong password",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
             
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  onTapOutside: (event) {
                    Border.all(color: Colors.white);
                  },
                  controller: Cpass,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password confirmation",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
             
              SizedBox(height: 20),
               
              ListTile(
                leading: Icon(Icons.person),
                title: Text(
                  "Role", 
                  style: TextStyle(
                    color: Colors.white, 
                    letterSpacing: 1, 
                    fontSize: 16, 
                    fontWeight: FontWeight.w700
                  )
                ),  
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            selected = "Admin";
                            if (selected == "Admin") {
                              admin =accentColor;
                              Customer = Colors.white;
                            } else {
                              admin = Colors.white;
                              Customer = accentColor;
                            }
                          });
                        }, 
                        child: Text(
                          "Administrator", 
                          style: TextStyle(color: admin)
                        )
                      ),
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            selected = "Customer";
                            if (selected == "Customer") {
                              Customer = accentColor;
                              admin = Colors.white;
                            } else {
                              Customer = Colors.white;
                              admin = accentColor;
                            }
                          });
                        }, 
                        child: Text(
                          "Customer", 
                          style: TextStyle(color: Customer)
                        )
                      ),
                    ),
                  ),
                ],
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
                title: Text("Already have an Account? login"),
                onTap: () {
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (context) => LoginPage())
                  );
                },
              ),

              Container(
                height: 55,
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: ElevatedButton(
                  onPressed: isLoading ? null : signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:accentColor,
                    foregroundColor:bgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)
                    )
                  ),
                  child: isLoading 
                    ? CircularProgressIndicator(color:bgColor)
                    : Text(
                        "Sign Up", 
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
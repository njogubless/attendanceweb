import 'package:attendanceweb/Core/color_constants.dart';
import 'package:attendanceweb/Features/Auth/auth.dart';
import 'package:attendanceweb/Features/Models/client.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class SignIn extends ConsumerStatefulWidget {
  const SignIn({super.key});

  @override
  ConsumerState<SignIn> createState() => _SignInState();
}

class _SignInState extends ConsumerState<SignIn> {
  // Instance of AuthService which accesses methods to
  // register and sign in with email and pass: used in an on pressed event
  final AuthService _auth = AuthService();
  // Form key for input validation
  final _formkey = GlobalKey<FormState>();
  bool loading = false;

  // Form fields, taking note of their states
  String email = '';
  String password = '';

  // Upon an attempt to register
  String error = '';

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.height < 600;
    
    // Adjust spacing based on screen size
    final double verticalSpacing = isSmallScreen ? 15.0 : 30.0;
    
    return loading
        ? const Loading()
        : Scaffold(
            backgroundColor: white,
            resizeToAvoidBottomInset: true, // Allow resizing when keyboard appears
            appBar: AppBar(
              backgroundColor: white,
              elevation: 0.0,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
            ),
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.fromLTRB(15.0, 30.0, 0.0, 0.0),
                        child: const Text('Welcome',
                            style: TextStyle(
                                fontSize: 50.0, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16.0, 80.0, 0.0, 0.0),
                        child: const Text('Back',
                            style: TextStyle(
                                fontSize: 80.0, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  SizedBox(height: verticalSpacing),
                  Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * (isSmallScreen ? 0.2 : 0.3)),
                      child: Form(
                        key: _formkey,
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'EMAIL',
                                  labelStyle: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.bold,
                                      color: darkGrey),
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: lightBlue))),
                              validator: (val) =>
                                  EmailValidator.validate(val!.trim())
                                      ? null
                                      : 'Enter a valid email address',
                              onChanged: (val) {
                                setState(() {
                                  email = val.trim();
                                });
                              },
                            ),
                            SizedBox(height: verticalSpacing * 0.7),
                            TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'PASSWORD',
                                  labelStyle: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.bold,
                                      color: darkGrey),
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: lightBlue))),
                              validator: (val) => val!.length < 6
                                  ? 'Password less than 6 characters long'
                                  : null,
                              onChanged: (val) {
                                setState(() {
                                  password = val.trim();
                                });
                              },
                              obscureText: true,
                            ),
                            SizedBox(height: verticalSpacing * 1.5),
                            SizedBox(
                              height: 40.0,
                              child: GestureDetector(
                                onTap: () async {
                                  if (_formkey.currentState!.validate()) {
                                    setState(() {
                                      loading = true;
                                    });
                                    // AuthService method to sign in user when validation is successful
                                    Client? result =
                                        await _auth.signInWithEmailAndPassword(
                                            email, password, ref);

                                    if (result == null) {
                                      setState(() {
                                        loading = false;
                                        error = 'Invalid login, please try again';
                                      });
                                    }
                                    // Else, the Wrapper gets a new user and shows the Home Page
                                  }
                                },
                                child: Material(
                                  borderRadius: BorderRadius.circular(20.0),
                                  shadowColor: Colors.blueAccent,
                                  color: Colors.blue,
                                  elevation: 7.0,
                                  child: const Center(
                                    child: Text(
                                      'SIGN IN',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Montserrat'),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: verticalSpacing * 0.7),
                          ],
                        ),
                      )),
                  SizedBox(height: verticalSpacing * 0.5),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Admin sign in',
                        style: TextStyle(fontFamily: 'Montserrat'),
                      ),
                      SizedBox(width: 5.0),
                    ],
                  ),
                  SizedBox(height: verticalSpacing * 0.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        error,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 5.0),
                    ],
                  ),
                  // Add padding at the bottom to ensure nothing is cut off
                  SizedBox(height: verticalSpacing),
                ],
              ),
            ),
          );
  }
}
import 'dart:ui';

import 'package:adda/models/achievement_model.dart';
import 'package:adda/pages/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rive/rive.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../models/user_model.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  var page = 1;//1 for sign in and 2 for sign up
  late Widget currentPage = signInWidget(context);
  String emailId = "", password = "",name="";

  bool isValid() {
    //Check if email and password is valid
    if (emailId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please enter email and password"),
      ));
      return false;
    }
    //check if email matches email regex
    if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(emailId)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please enter a valid email"),
      ));
      return false;
    }
    if (password.length<8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            "Password must be greater than 8 and contain a lowercase letter and a number"),
      ));
      return false;
    }
    return true;
  }

  void onSignIn()async {
    if (!isValid())return;
    final auth = FirebaseAuth.instance;
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Signing in..."),
    ));
    if (page == 2) {
      try {
        final cred = await auth.createUserWithEmailAndPassword
          (email: emailId, password: password);
        await cred.user!.sendEmailVerification();
        await createUserDoc(cred);
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()));
        }
      }
      on FirebaseAuthException catch (e,stack) {
        String error = "Something went wrong. Please try again later.";
        if (e.code == 'weak-password') {
          error = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          error = 'The account already exists for that email.';
        }
        else {
          FirebaseCrashlytics.instance.recordError(e, stack);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error),
          ));
        }
      }
      catch(error,stack) {
        FirebaseCrashlytics.instance.recordError(error, stack);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Couldn't create account. Please try again later."),
          ));
        }
      }

    } else {
      //sign in the user with email and password
      try {
        await auth.signInWithEmailAndPassword(email: emailId, password: password);
        if (context.mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=>const HomePage()));
        }
      }
      on FirebaseAuthException catch (e,stack) {
        String error = "Something went wrong. Please try again later.";
        if (e.code == 'user-not-found') {
          error = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          error = 'Wrong password provided for that user.';
        }
        else {
          FirebaseCrashlytics.instance.recordError(e, stack);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error),
          ));
        }
      }
      catch (error,stack) {
        FirebaseCrashlytics.instance.recordError(error, stack);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Couldn't sign in. Please try again later."),
          ));
        }
      }
    }
  }

  void googleSignIn()async {
    //Sign in with await google and check for errors
    try {
      await signInWithGoogle();
    }
    catch (error,stack) {
      FirebaseCrashlytics.instance.recordError(error, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Couldn't sign in. Please try again later."),
        ));
      }
    }
  }

  Future<void> createUserDoc(UserCredential cred) async {
    // create user model from cred data
    String noNullName = cred.user!.displayName==null? name : cred.user!.displayName!;
    final user = UserModel(username: cred.user!.uid, name: noNullName, email: cred.user!.email!,
    uid: cred.user!.uid,photoUrl: cred.user!.photoURL);
    await createCaches(cred);
    return FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set(user.toJson());
  }

  Future<void> createCaches(UserCredential cred) async {
    List<Achievement> achievements = [];
    final viewsAchievement = Achievement(
      title: "Views",
      description: "Got {views} views on profile",
      icon: FontAwesomeIcons.eye,
      colors: [
        Colors.pinkAccent.shade400,
        Colors.white,
      ],
    );
    final messagesAchievement = Achievement(
      title: "Messages",
      description: "Sent {messageCount} messages",
      icon: FontAwesomeIcons.comment,
      colors: [
        Colors.pinkAccent.shade400,
        Colors.white,
      ],
    );
    final accountCreationAchievement = Achievement(
      title: "Account Creation",
      description: "Created account on {creationDate}",
      icon: FontAwesomeIcons.user,
      colors: [
        Colors.pinkAccent.shade400,
        Colors.white,
      ],
    );
    achievements.add(viewsAchievement);
    achievements.add(messagesAchievement);
    achievements.add(accountCreationAchievement);
    final firestore = FirebaseFirestore.instance;
    return firestore.collection("userCache").doc(cred.user?.uid).set({
      "achievements":achievements.map((e) => e.toJson()).toList(),
      "views":0,
      "messageCount":0,
    });
  }

  Future<void> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    // Once signed in, return the UserCredential
    final cred = await FirebaseAuth.instance.signInWithCredential(credential);
    //check if user id already exists in firestore
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
    if (!userDoc.exists) {
      await createUserDoc(cred);
    }
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()));
    }
  }

  void togglePage(BuildContext context) {
    setState(() {
      if (page==1) {
        page = 2;
        currentPage = signUpWidget(context);
      } else {
        page = 1;
        currentPage = signInWidget(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Resize to bottom false
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const RiveAnimation.asset(
            "assets/shapes_background.riv",
            fit: BoxFit.fill,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.0)),
            ),
          ),
          Column(
            children: [
              //Title with the name Adda
              Padding(
                //16 padding on all side
                padding: const EdgeInsets.fromLTRB(16, 90, 16, 0),
                child: Text(
                  "Sign in to Adda",
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontSize: 32, letterSpacing: 1.5, wordSpacing: 1.7),
                ),
              ),
              //A description text of the app. Join your friends around the world.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  "Meet your friends around the world.",
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              //Animated switcher with sing in and sign up. with rotation transition
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: currentPage,
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 120,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: onSignIn,
                        child: RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                // Check page for sign up or sign in
                                text: page == 2
                                    ? "Sign up with email"
                                    : "Sign in with email",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .inverseSurface),
                              ),
                              //Widget span with a sized box of width 10
                              const WidgetSpan(
                                  child: SizedBox(
                                    width: 10,
                                  )),
                              WidgetSpan(
                                  child: Icon(
                                    FontAwesomeIcons.rightToBracket,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.inverseSurface,
                                  )),
                            ])),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  // if page is 2 show not a user of adda else show already a user of adda
                  page == 2
                      ? "Already a user of Adda?"
                      : "Not a user of Adda?",
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.grey.shade400,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 130,
                  height: 40,
                  child: TextButton(
                    onPressed:()=> {
                      togglePage(context)
                    },
                    child: Text(
                      //If page is 2 show create account or show login
                      page == 2 ? "Login" : "Create Account",
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(
                          color: Colors.blueAccent.shade400)
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Card signUpWidget(BuildContext context) {
    return Card(
      key: const ValueKey<int>(2),
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.only(top: 50, left: 8, right: 8),
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
        height: 360,
        width: MediaQuery.of(context).size.width-16,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: [
          TextField(
            style: TextStyle(
              color: Theme.of(context).colorScheme.inverseSurface,
              fontSize: 12,
            ),
            //set name
            onChanged: (value) {
              setState(() {
                name = value;
              });
            },
            decoration: const InputDecoration(
                prefixIcon: Icon(FontAwesomeIcons.signature),
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.all(Radius.circular(16.0)),
                ),
                label: Text("Full name"),
                hintText: "First and last name"),
          ),
          const SizedBox(
            height: 10,
          ),
          emailField(context),
          const SizedBox(
            height: 10,
          ),
          passwordField(context),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: Text(
              "OR Sign up with",
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Colors.grey.shade400,
              ),
            ),
          ),
          // A row with three icon buttons
          providerRow(),
        ]
        ),
      ),
    );
  }

  Row providerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed:googleSignIn,
          icon: const Icon(FontAwesomeIcons.google),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(FontAwesomeIcons.apple),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(FontAwesomeIcons.phone),
        ),
      ],
    );
  }
  Card signInWidget(BuildContext context) {
    return Card(
      key: const ValueKey<int>(1),
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.only(top: 50, left: 8, right: 8),
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
        height: 360,
        width: MediaQuery.of(context).size.width-16,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: [
          emailField(context),
          const SizedBox(
            height: 10,
          ),
          passwordField(context),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: Text(
              "OR Sign in with",
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Colors.grey.shade400,
              ),
            ),
          ),
          // A row with three icon buttons
          Padding(
            padding: const EdgeInsets.only(top: 70),
            child: providerRow(),
          ),
        ]
        ),
      ),
    );
  }

  TextField emailField(BuildContext context) {
    return TextField(
      style: TextStyle(
        color: Theme.of(context).colorScheme.inverseSurface,
        fontSize: 14,
      ),
      onChanged: (value) {
        setState(() {
          emailId = value;
        });
      },
      decoration: const InputDecoration(
          prefixIcon: Icon(FontAwesomeIcons.envelope),
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(16.0)),
          ),
          label: Text("Email"),
          hintText: "Your email id"),
    );
  }

  TextField passwordField(BuildContext context) {
    return TextField(
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      onChanged: (value) {
        setState(() {
          password = value;
        });
      },
      style: TextStyle(
        color: Theme.of(context).colorScheme.inverseSurface,
        fontSize: 10,
      ),
      decoration: const InputDecoration(
          prefixIcon: Icon(FontAwesomeIcons.lock),
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(16.0)),
          ),
          label: Text("Password"),
          hintText: "Password"),
    );
  }
}
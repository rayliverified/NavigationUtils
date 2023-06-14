// ignore_for_file: avoid_print

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Firebase Auth Test',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FirebaseAuth firebaseAuth;
  late Stream<User?> firebaseAuthUserStream;
  late StreamSubscription firebaseAuthListener;

  @override
  void initState() {
    super.initState();
    firebaseAuth = FirebaseAuth.instance;
    firebaseAuthUserStream =
        FirebaseAuth.instance.authStateChanges().asBroadcastStream();
    firebaseAuthListener = firebaseAuthUserStream.listen((user) {
      print('AuthStateChanges: $user');
    });
  }

  @override
  void dispose() {
    firebaseAuthListener.cancel();
    super.dispose();
  }

  void onLogin() async {
    await firebaseAuth.signInWithEmailAndPassword(
        email: 'test@testuser.com', password: '12345678');
  }

  void onLogout() async {
    await firebaseAuth.signOut();
  }

  @override
  Widget build(BuildContext parentContext) {
    print('Build Home');
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StreamBuilder<String?>(
                  initialData: null,
                  stream: firebaseAuthUserStream.map((event) => event?.uid),
                  builder: (context, snapshot) {
                    print('Build Stream Builder');
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.hasData) {
                      print(snapshot.data);
                      print('Rebuild Stream');
                      return Text('User: ${snapshot.data!}');
                    }

                    return const Text('User: None');
                  }),
              TextButton(
                onPressed: onLogin,
                child: const Text('Login'),
              ),
              TextButton(
                onPressed: onLogout,
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

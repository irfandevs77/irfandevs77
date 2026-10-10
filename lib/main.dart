import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!FirebaseEnvironment.isConfigured) {
    runApp(const IrfanDevs77App(firebaseConfigured: false));
    return;
  }

  try {
    await Firebase.initializeApp(options: FirebaseEnvironment.webOptions);
    runApp(const IrfanDevs77App(firebaseConfigured: true));
  } on FirebaseException catch (error) {
    runApp(
      IrfanDevs77App(
        firebaseConfigured: false,
        configurationError: error.message ?? error.code,
      ),
    );
  }
}

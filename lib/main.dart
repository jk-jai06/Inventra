import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
export 'app/app.dart' show MyApp;
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/prediction_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseInitStatus firebaseStatus = FirebaseInitStatus.notInitialized;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    firebaseStatus = FirebaseInitStatus.ok;
    debugPrint('[Firebase] Initialized successfully');
  } on FirebaseException catch (e) {
    debugPrint(
      '[Firebase] Initialization failed: ${e.code} — ${e.message}',
    );
    firebaseStatus = FirebaseInitStatus.error;
  } catch (e) {
    debugPrint('[Firebase] Unexpected initialization error: $e');
    firebaseStatus = FirebaseInitStatus.error;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ProductProvider(context.read<AuthProvider>()),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (context) => CustomerProvider(context.read<AuthProvider>()),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (context) => InvoiceProvider(context.read<AuthProvider>()),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (context) => AnalyticsProvider(context.read<AuthProvider>()),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => PredictionProvider(),
        ),
      ],
      child: InventraApp(
        firebaseStatus: firebaseStatus,
      ),
    ),
  );
}

/// Tracks the result of Firebase initialization.
enum FirebaseInitStatus {
  notInitialized,
  ok,
  error,
}

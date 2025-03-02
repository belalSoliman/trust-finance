import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:trust_finiance/firebase_options.dart';
import 'package:trust_finiance/models/customer_model/customer_model.dart';
import 'package:trust_finiance/models/invoice_model.dart';
import 'package:trust_finiance/trust_app.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Hive - Use Hive.initFlutter() directly for simplicity
  await Hive.initFlutter();

  // Register Hive adapters - this is correct
  Hive.registerAdapter(CustomerModelAdapter());
  Hive.registerAdapter(InvoiceModelAdapter());
  Hive.registerAdapter(InvoiceItemModelAdapter());

  // Open Hive boxes - this is correct
  await Hive.openBox<CustomerModel>('customers');
  await Hive.openBox<InvoiceModel>('invoices');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Remove splash screen when initialization is complete
  FlutterNativeSplash.remove();
  runApp(const TrustApp());
}

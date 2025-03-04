import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:trust_finiance/firebase_options.dart';
import 'package:trust_finiance/models/customer_model/customer_model.dart';
import 'package:trust_finiance/models/invoice_model/invoice_model.dart';
import 'package:trust_finiance/trust_app.dart';
import 'package:trust_finiance/utils/networt_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Hive - Use Hive.initFlutter() directly for simplicity
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(CustomerModelAdapter());
  Hive.registerAdapter(InvoiceModelAdapter());
  Hive.registerAdapter(InvoiceItemModelAdapter());

  // Open Hive boxes
  await Hive.openBox<CustomerModel>('customers');
  await Hive.openBox<InvoiceModel>('invoices');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize network service
  final networkService = NetworkStatusService();
  await networkService.initialize();

  // Remove splash screen when initialization is complete
  FlutterNativeSplash.remove();
  runApp(const TrustApp());
}

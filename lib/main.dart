import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:trust_finiance/trust_app.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Your initialization code here

  // Remove splash screen when initialization is complete
  FlutterNativeSplash.remove();
  runApp(const TrustApp());
}

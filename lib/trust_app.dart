//the app widget
import 'package:flutter/material.dart';
import 'package:trust_finiance/utils/constant/app_const.dart';
import 'package:trust_finiance/utils/navigation/app_route.dart';
import 'package:trust_finiance/utils/theme.dart';
import 'package:trust_finiance/view/home/home.dart';

class TrustApp extends StatelessWidget {
  const TrustApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConst.appName,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.system,
      home: const Home(),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRoute().geneateRoute,
    );
  }
}

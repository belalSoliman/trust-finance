import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_cubit.dart';
import 'package:trust_finiance/repos/auth_repo.dart';
import 'package:trust_finiance/utils/constant/app_const.dart';
import 'package:trust_finiance/utils/navigation/app_route.dart';
import 'package:trust_finiance/utils/theme.dart';
import 'package:trust_finiance/view/auth/login_page.dart';

class TrustApp extends StatelessWidget {
  const TrustApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(
        authRepository: AuthRepository(),
      )..checkInitialSetup(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: AppConst.appName,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.system,
        home: const LoginPage(),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: AppRoute().geneateRoute,
      ),
    );
  }
}

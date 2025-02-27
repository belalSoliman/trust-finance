import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_cubit.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_state.dart';
import 'package:trust_finiance/repos/auth_repo.dart';
import 'package:trust_finiance/utils/constant/app_const.dart';
import 'package:trust_finiance/utils/navigation/app_route.dart';
import 'package:trust_finiance/utils/theme.dart';
import 'package:trust_finiance/view/auth/login_page.dart';
import 'package:trust_finiance/view/home/home.dart';

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
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return ScreenUtilInit(
            designSize: const Size(360, 690),
            splitScreenMode: true,
            builder: (_, child) {
              return MaterialApp(
                navigatorKey: navigatorKey,
                title: AppConst.appName,
                theme: AppTheme.lightTheme,
                themeMode: ThemeMode.system,
                debugShowCheckedModeBanner: false,
                home: child,
                onGenerateRoute: AppRoute().geneateRoute,
              );
            },
            child: _handleAuthState(state),
          );
        },
      ),
    );
  }

  Widget _handleAuthState(AuthState state) {
    if (state is AuthLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }
    if (state is Authenticated) {
      return const Home();
    }
    return const LoginPage();
  }
}

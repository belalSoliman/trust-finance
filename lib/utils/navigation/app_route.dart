import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trust_finiance/cubit/invoice_cuibt/invoice_cubit.dart';
import 'package:trust_finiance/models/user_model.dart'; // Import UserModel
import 'package:trust_finiance/repos/invoice_repo.dart' show InvoiceRepository;
import 'package:trust_finiance/utils/navigation/routes.dart';
import 'package:trust_finiance/view/auth/login_page.dart';
import 'package:trust_finiance/view/customer/widget/edit_customer_information.dart';
import 'package:trust_finiance/view/home/home.dart';
import 'package:trust_finiance/view/home/widget/add_customer.dart';
import 'package:trust_finiance/view/home/widget/add_invoice.dart';
import 'package:trust_finiance/view/home/widget/add_payment.dart';

class AppRoute {
  Route? geneateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );
      case Routes.home:
        return MaterialPageRoute(builder: (_) => Home());
      case Routes.createInovice:
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) {
              // Create the invoice repository with the current user
              final firebaseUser = FirebaseAuth.instance.currentUser;
              if (firebaseUser == null) {
                // Handle the case where user is not logged in
                Navigator.pushReplacementNamed(context, Routes.login);
                throw Exception('User not authenticated');
              }

              // Convert Firebase User to UserModel
              final userModel = UserModel(
                uid: firebaseUser.uid,
                email: firebaseUser.email ?? '',
                name: firebaseUser.displayName ??
                    firebaseUser.email?.split('@')[0] ??
                    'User', // Use displayName or email prefix
                role:
                    UserRole.cashier, // Default role or fetch from user claims
                isActive: true, // Default to active
              );

              final invoiceRepository = InvoiceRepository(
                currentUser:
                    userModel, // Pass the UserModel instead of Firebase User
              );

              // Create the InvoiceCubit with the repository
              return InvoiceCubit(invoiceRepository: invoiceRepository);
            },
            child: const CreateInvoicePage(),
          ),
        );

      case Routes.addCustomer:
        return MaterialPageRoute(builder: (_) => const AddCustomerPage());

      case Routes.addPayment:
        return MaterialPageRoute(builder: (_) => const AddPaymentPage());

      default:
        return null;
    }
  }
}

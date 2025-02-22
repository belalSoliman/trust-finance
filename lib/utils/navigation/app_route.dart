//i will create a class that will hold all the routes in the app
import 'package:flutter/material.dart';
import 'package:trust_finiance/utils/navigation/routes.dart';
import 'package:trust_finiance/view/home/home.dart';
import 'package:trust_finiance/view/home/widget/add_customer.dart';
import 'package:trust_finiance/view/home/widget/add_invoice.dart';
import 'package:trust_finiance/view/home/widget/add_payment.dart';

class AppRoute {
  Route? geneateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.home:
        return MaterialPageRoute(builder: (_) => Home());
      case Routes.createInovice:
        return MaterialPageRoute(builder: (_) => CreateInvoicePage());

      case Routes.addCustomer:
        return MaterialPageRoute(builder: (_) => AddCustomerPage());

      case Routes.addPayment:
        return MaterialPageRoute(builder: (_) => AddPaymentPage());

      default:
        return null;
    }
  }
}

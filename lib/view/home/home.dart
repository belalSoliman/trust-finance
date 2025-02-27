import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_cubit.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_state.dart';
import 'package:trust_finiance/cubit/customer_cubit/customer_cubit_cubit.dart';
import 'package:trust_finiance/repos/customer_repo.dart';
import 'package:trust_finiance/utils/constant/app_const.dart';
import 'package:trust_finiance/view/auth/create_user.dart';
import 'package:trust_finiance/view/home/widget/Todays_Collections.dart';
import 'package:trust_finiance/view/home/widget/current_date.dart';
import 'package:trust_finiance/view/home/widget/custom_fab.dart';
import 'package:trust_finiance/view/customer/customer_list.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(context),
      body: _buildBody(),
      floatingActionButton: FloatingBtn(),
    );
  }
}

AppBar _buildAppBar() {
  return AppBar(
    title: const Text(AppConst.homeTitle),
  );
}

Widget _buildBody() {
  return LayoutBuilder(builder: (context, constraints) {
    // Determine if we're on a tablet/wide screen based on constraints
    final isWideScreen = constraints.maxWidth > 600;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0.r), // Responsive padding with ScreenUtil
        child: isWideScreen
            ? _buildWideScreenLayout()
            : _buildNarrowScreenLayout(),
      ),
    );
  });
}

Widget _buildNarrowScreenLayout() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CurrentDate(),
      SizedBox(height: 20.h), // Responsive height with ScreenUtil
      TodaysCollections(),
      SizedBox(height: 20.h),
      BlocProvider(
        create: (context) => CustomerCubit(
          customerRepository: CustomerRepository(
            currentUser:
                (context.read<AuthCubit>().state as Authenticated).user,
          ),
        ),
        child: CustomerList(),
      ),
    ],
  );
}

Widget _buildWideScreenLayout() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CurrentDate(),
      SizedBox(height: 20.h),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Today's Collections
          Expanded(
            flex: 2,
            child: TodaysCollections(),
          ),
          SizedBox(width: 20.w), // Responsive width spacing
          // Right side: Customer List
          Expanded(
            flex: 3,
            child: BlocProvider(
              create: (context) => CustomerCubit(
                customerRepository: CustomerRepository(
                  currentUser:
                      (context.read<AuthCubit>().state as Authenticated).user,
                ),
              ),
              child: CustomerList(),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildDrawer(BuildContext context) {
  return BlocBuilder<AuthCubit, AuthState>(
    builder: (context, state) {
      final isSuperAdmin = state is Authenticated &&
          state.user.role.toString() == 'UserRole.superAdmin';

      // Debug logging
      if (state is Authenticated) {
        debugPrint('Current user details:');
        debugPrint('Email: ${state.user.email}');
        debugPrint('Role: ${state.user.role}');
        debugPrint('Is Super Admin: $isSuperAdmin');
      }

      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    AppConst.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (state is Authenticated)
                    Text(
                      ' ${state.user.role.name}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            // User Management Section for Super Admin
            if (isSuperAdmin) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'User Management',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Create New User'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateUserPage(),
                    ),
                  );
                },
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<AuthCubit>().signOut();
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

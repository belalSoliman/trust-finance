import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_cubit.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_state.dart';
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
  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurrentDate(),
          TodaysCollections(),
          CustomerList(),
        ],
      ),
    ),
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
                      'Role: ${state.user.role.name}',
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

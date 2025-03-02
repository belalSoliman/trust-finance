import 'dart:async';
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

// Service for managing customer list refreshes
class CustomerListRefreshService {
  // Singleton pattern
  static final CustomerListRefreshService _instance =
      CustomerListRefreshService._internal();
  factory CustomerListRefreshService() => _instance;
  CustomerListRefreshService._internal();

  // Stream controller for refresh events
  final StreamController<int> _refreshController =
      StreamController<int>.broadcast();
  Stream<int> get refreshStream => _refreshController.stream;

  // Counter for refresh events
  int _refreshCount = 0;

  // Method to trigger a refresh
  void triggerRefresh() {
    _refreshCount++;
    debugPrint(
        'CustomerListRefreshService: Triggering refresh: $_refreshCount');
    _refreshController.add(_refreshCount);
  }

  // Clean up resources
  void dispose() {
    _refreshController.close();
  }
}

class Home extends StatefulWidget {
  // Static method to refresh customer list from anywhere
  static void refreshCustomerList() {
    try {
      debugPrint('Home.refreshCustomerList: Starting refresh...');
      CustomerListRefreshService().triggerRefresh();
      debugPrint('Home.refreshCustomerList: Refresh triggered');
    } catch (e) {
      debugPrint('Error in Home.refreshCustomerList: $e');
    }
  }

  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Stream subscription to listen for refresh events
  StreamSubscription? _refreshSubscription;
  int _refreshCount = 0;

  @override
  void initState() {
    super.initState();

    // Subscribe to refresh events
    _refreshSubscription =
        CustomerListRefreshService().refreshStream.listen((count) {
      if (mounted) {
        setState(() {
          _refreshCount = count;
          debugPrint('Home received refresh event: $_refreshCount');
        });
      }
    });
  }

  @override
  void dispose() {
    // Clean up subscription
    _refreshSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(context),
      body: SafeArea(child: _buildBody()),
      floatingActionButton: FloatingBtn(),
    );
  }

  Widget _buildCustomerListSection() {
    // Calculate a fixed height for the customer list section
    final screenHeight = MediaQuery.of(context).size.height;
    final listHeight = screenHeight * 0.5; // Use 50% of screen height

    return SizedBox(
      height: listHeight,
      child: StreamBuilder<int>(
        stream: CustomerListRefreshService().refreshStream,
        initialData: _refreshCount,
        builder: (context, snapshot) {
          final refreshCount = snapshot.data ?? 0;
          debugPrint('Building customer list, refresh count: $refreshCount');

          return BlocProvider(
            key: ValueKey('customer_list_$refreshCount'),
            create: (context) {
              debugPrint(
                  'Creating new CustomerCubit for refresh: $refreshCount');
              try {
                final authState = context.read<AuthCubit>().state;
                if (authState is! Authenticated) {
                  throw Exception('User not authenticated');
                }

                final cubit = CustomerCubit(
                  customerRepository: CustomerRepository(
                    currentUser: authState.user,
                  ),
                );

                // Load customers after build is complete
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!cubit.isClosed) {
                    cubit.loadCustomers();
                  }
                });

                return cubit;
              } catch (e) {
                debugPrint('Error creating CustomerCubit: $e');
                rethrow;
              }
            },
            child: const CustomerList(),
          );
        },
      ),
    );
  }

  // Other methods moved to class level for better organization
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(AppConst.homeTitle),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _buildNarrowScreenLayout();
          },
        ),
      ),
    );
  }

  Widget _buildNarrowScreenLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CurrentDate(),
        SizedBox(height: 20.h),
        const TodaysCollections(),
        SizedBox(height: 20.h),
        _buildCustomerListSection(),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isSuperAdmin = state is Authenticated &&
            state.user.role.toString() == 'UserRole.superAdmin';

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
}

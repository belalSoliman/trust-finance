import 'package:flutter/material.dart';
import 'package:trust_finiance/view/home/widget/Todays_Collections.dart';
import 'package:trust_finiance/view/home/widget/current_date.dart';
import 'package:trust_finiance/view/home/widget/customer_list.dart';

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
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //todo :add your action here
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

AppBar _buildAppBar() {
  return AppBar(
    title: const Text('Trust Finance'),
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

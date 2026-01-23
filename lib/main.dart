import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transaction_scraper/viewmodels/dashboard_viewmodel.dart';
import 'screens/dashboard.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => DashboardViewmodel(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transaction Scrapper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

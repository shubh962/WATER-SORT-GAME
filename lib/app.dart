import 'package:flutter/material.dart';
import 'package:water_sort/config/app_config.dart';
import 'package:water_sort/ui/home_screen.dart';
import 'package:water_sort/ui/theme.dart';

class WaterSortApp extends StatelessWidget {
  const WaterSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}

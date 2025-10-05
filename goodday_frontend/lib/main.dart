import 'package:flutter/material.dart';
//import 'package:maps_google_v2/current_address/google_maps_screen.dart';
import 'package:maps_google_v2/current_address/search_location_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LocationScreen(),
    );
  }
}

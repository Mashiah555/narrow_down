import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/setup/presentation/screens/setup_screen.dart';

void main() {
  runApp(const ProviderScope(child: NarrowDownApp()));
}

class NarrowDownApp extends StatelessWidget {
  const NarrowDownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Narrow Down',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const SetupScreen(),
    );
  }
}

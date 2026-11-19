import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/theme.dart';
import 'screens/gate_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.ink,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const RumboApp());
}

class RumboApp extends StatelessWidget {
  const RumboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rumbo',
      debugShowCheckedModeBanner: false,
      theme: buildRumboTheme(),
      home: const GateScreen(),
    );
  }
}

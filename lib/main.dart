import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/device_provider.dart';
import 'screens/shell.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait — no rotation allowed.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const SmartGrowApp());
}

class SmartGrowApp extends StatefulWidget {
  const SmartGrowApp({super.key});

  @override
  State<SmartGrowApp> createState() => _SmartGrowAppState();
}

class _SmartGrowAppState extends State<SmartGrowApp> {
  bool _showSplash = true;

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DeviceProvider(),
      child: MaterialApp(
        title: 'SmartGrow',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        darkTheme: buildTheme(dark: true),
        themeMode: ThemeMode.system,
        home: _showSplash
            ? SplashScreen(onComplete: _onSplashComplete)
            : const Shell(),
      ),
    );
  }
}

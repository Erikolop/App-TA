import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/device_provider.dart';
import 'screens/shell.dart';

void main() {
  runApp(const SmartGrowApp());
}

class SmartGrowApp extends StatelessWidget {
  const SmartGrowApp({super.key});

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
        home: const Shell(),
      ),
    );
  }
}

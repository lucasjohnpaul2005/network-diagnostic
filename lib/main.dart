import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/network_monitor_provider.dart';
import 'providers/network_diagnostic_provider.dart';
import 'screens/home_screen.dart';
import 'screens/activity_one_screen.dart';
import 'screens/activity_two_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/network_monitor_screen.dart';
import 'screens/network_diagnostic_screen.dart';
import 'providers/local_mesh_chat_provider.dart';
import 'screens/local_mesh_chat_screen.dart';

void main() {
  runApp(const PortfolioApp());
}


class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => NetworkMonitorProvider()),
        ChangeNotifierProvider(create: (_) => NetworkDiagnosticProvider()),
        ChangeNotifierProvider(create: (_) => LocalMeshChatProvider()),
      ],
      child: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'Flutter Portfolio',
            debugShowCheckedModeBanner: false,
            themeMode: appState.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            initialRoute: HomeScreen.routeName,
            // Centralized named routes -> multi-screen navigation.
            routes: {
              HomeScreen.routeName: (_) => const HomeScreen(),
              ActivityOneScreen.routeName: (_) => const ActivityOneScreen(),
              ActivityTwoScreen.routeName: (_) => const ActivityTwoScreen(),
              SettingsScreen.routeName: (_) => const SettingsScreen(),
              NetworkMonitorScreen.routeName: (_) => const NetworkMonitorScreen(),
              NetworkDiagnosticScreen.routeName: (_) => const NetworkDiagnosticScreen(),
              LocalMeshChatScreen.routeName: (_) => const LocalMeshChatScreen(),
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/finance_controller.dart';
import 'controllers/theme_controller.dart';
import 'services/firebase_service.dart';
import 'views/auth/login_page.dart';
import 'views/navigation_shell.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Catch configuration errors (e.g. missing google-services.json) 
    // and automatically enable the premium mock database sandbox.
    FirebaseService.initMock();
    await FirebaseService.loadMockDb();
    FirebaseService.ensureDemoAccountInitialized();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => FinanceController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          final isDark = themeController.isDarkMode;
          return MaterialApp(
            title: 'finsim',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: isDark ? Brightness.dark : Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF00BFA5),
                brightness: isDark ? Brightness.dark : Brightness.light,
              ),
            ),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    if (auth.isAuthenticated) {
      return const NavigationShell();
    } else {
      return const LoginPage();
    }
  }
}

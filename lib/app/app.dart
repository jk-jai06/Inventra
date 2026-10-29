import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main_navigation_shell.dart';
import '../core/widgets/splash_widget.dart';
import 'theme.dart';

class InventraApp extends StatelessWidget {
  final dynamic firebaseStatus;
  const InventraApp({super.key, this.firebaseStatus});

  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventra',
      theme: AppTheme.light,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
            // Loading authentication state
          if (auth.status == AuthStatus.unknown) {
            return const Scaffold(
              body: SplashWidget(),
            );
          }

          // User is authenticated
          if (auth.status == AuthStatus.authenticated) {
            // Shop session is loading (reading users/{uid} document)
            if (auth.shopId == null && auth.role == null) {
              return const Scaffold(
                body: SplashWidget(),
              );
            }

            // Shop session ready, show authenticated app
            if (auth.shopId != null && auth.role != null) {
              return const MainNavigationShell();
            }

            // Shop session failed to load
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Failed to load shop session'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => auth.signOut(),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            );
          }

          // User is not authenticated, show auth navigation
          return _buildAuthNavigation();
        },
      ),
    );
  }

  /// Builds the authentication navigation (login/register).
  /// Uses a Navigator to handle transitions between login and register screens.
  Widget _buildAuthNavigation() {
    return Navigator(
      pages: const [
        MaterialPage(
          child: LoginScreen(),
        ),
      ],
      onDidRemovePage: (page) {},
    );
  }
}

import 'package:flutter/material.dart';

import '../services/app_session.dart';
import 'admin_dashboard_screen.dart';
import 'home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSession.instance,
      builder: (context, _) {
        if (AppSession.instance.user?.isAdmin == true) {
          return const AdminDashboardScreen();
        }
        return const HomeScreen();
      },
    );
  }
}

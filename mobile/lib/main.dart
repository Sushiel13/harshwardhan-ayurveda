import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'theme.dart';
import 'services/api.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_shell.dart';
import 'screens/admin/admin_shell.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  runApp(const HiaApp());
}

class HiaApp extends StatelessWidget {
  const HiaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AuthGate(),
    );
  }
}

/// Decides what to show: login → student app → (admins can switch to the admin panel).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Api.auth.onAuthStateChange,
      builder: (context, _) {
        final user = Api.auth.currentUser;
        if (user == null) return const LoginScreen();
        return FutureBuilder<Map<String, dynamic>?>(
          key: ValueKey(user.id),
          future: Api.myProfile(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Scaffold(body: Loading());
            final p = snap.data;
            if (p?['is_blocked'] == true) return const BlockedScreen();
            return p?['role'] == 'admin' ? const RoleSwitcher() : const StudentShell();
          },
        );
      },
    );
  }
}

/// Admins open straight into the admin panel and can flip to the student view.
class RoleSwitcher extends StatefulWidget {
  const RoleSwitcher({super.key});
  @override
  State<RoleSwitcher> createState() => _RoleSwitcherState();
}

class _RoleSwitcherState extends State<RoleSwitcher> {
  bool admin = true;
  @override
  Widget build(BuildContext context) => admin
      ? AdminShell(onStudentView: () => setState(() => admin = false))
      : StudentShell(onAdminView: () => setState(() => admin = true));
}

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.block, size: 48, color: AppColors.clay),
              const SizedBox(height: 16),
              Text('Account suspended', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Please contact the institute for help.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton(onPressed: () => Api.auth.signOut(), child: const Text('Sign out')),
            ]),
          ),
        ),
      );
}

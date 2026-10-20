import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'theme.dart';
import 'services/api.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_shell.dart';
import 'screens/admin/admin_shell.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Show a readable message instead of a blank/grey screen if a widget fails.
  ErrorWidget.builder = (details) => Material(
        color: AppColors.ivory,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Something went wrong:\n${details.exceptionAsString()}', textAlign: TextAlign.center),
          ),
        ),
      );
  // Draw the first frame immediately; connect to the backend behind a splash screen.
  runApp(const HiaApp());
}

/// Returns a problem description if the build-time settings are missing, else null.
String? configProblem() {
  final url = AppConfig.supabaseUrl, key = AppConfig.supabaseAnonKey;
  if (url.isEmpty || key.isEmpty) return 'SUPABASE_URL / SUPABASE_ANON_KEY were not provided when this app was built.';
  if (url.contains('placeholder') || key == 'placeholder') return 'This app was built with placeholder settings — the GitHub secrets SUPABASE_URL and SUPABASE_ANON_KEY were not found.';
  if (!url.startsWith('https://')) return 'SUPABASE_URL must start with https:// (got "$url").';
  return null;
}

Future<void> _boot() async {
  final problem = configProblem();
  if (problem != null) throw Exception(problem);
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey)
      .timeout(const Duration(seconds: 20));
}

class HiaApp extends StatefulWidget {
  const HiaApp({super.key});
  @override
  State<HiaApp> createState() => _HiaAppState();
}

class _HiaAppState extends State<HiaApp> {
  late Future<void> _ready = _boot();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: FutureBuilder<void>(
        future: _ready,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) return const SplashScreen();
          if (s.hasError) {
            return SetupErrorScreen(
              message: '${s.error}'.replaceFirst('Exception: ', ''),
              onRetry: () => setState(() => _ready = _boot()),
            );
          }
          return const AuthGate();
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppColors.forest,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Emblem(size: 84),
            SizedBox(height: 18),
            BrandTitle(light: true),
            SizedBox(height: 28),
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brassLight)),
          ]),
        ),
      );
}

class SetupErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const SetupErrorScreen({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Emblem(size: 56),
              const SizedBox(height: 20),
              Text('App could not start', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(message, style: const TextStyle(color: AppColors.inkSoft, height: 1.5)),
              const SizedBox(height: 24),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ]),
          ),
        ),
      );
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

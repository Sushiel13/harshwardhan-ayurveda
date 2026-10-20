import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool signup = false, busy = false;
  final name = TextEditingController(), phone = TextEditingController(), email = TextEditingController(), pass = TextEditingController();
  final _form = GlobalKey<FormState>();

  Future<void> submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      if (signup) {
        final r = await Api.auth.signUp(
          email: email.text.trim(),
          password: pass.text,
          data: {'full_name': name.text.trim(), 'phone': phone.text.trim()},
        );
        if (r.session == null && mounted) toast(context, 'Check your email to confirm your account, then log in.');
      } else {
        await Api.auth.signInWithPassword(email: email.text.trim(), password: pass.text);
      }
    } on AuthException catch (e) {
      if (mounted) toast(context, e.message);
    } catch (e) {
      if (mounted) toast(context, '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> forgot() async {
    if (email.text.trim().isEmpty) return toast(context, 'Enter your email first');
    await Api.auth.resetPasswordForEmail(email.text.trim());
    if (mounted) toast(context, 'Password reset link sent to your email.');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          Container(
            width: double.infinity,
            height: 280,
            color: AppColors.forest,
            child: Stack(children: [
              Positioned(right: -60, top: -40, child: CustomPaint(size: const Size(300, 300), painter: PetalPainter(opacity: .25))),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const BrandTitle(light: true),
                    const Spacer(),
                    Text(signup ? 'Begin your journey' : 'Welcome back',
                        style: t.headlineLarge?.copyWith(color: AppColors.ivory, fontSize: 34)),
                    const SizedBox(height: 6),
                    Text('One account for the app and the website.', style: TextStyle(color: AppColors.ivory.withOpacity(.7))),
                    const SizedBox(height: 28),
                  ]),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (signup) ...[
                  TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Full name'), validator: _req),
                  const SizedBox(height: 14),
                  TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number'), validator: _req),
                  const SizedBox(height: 14),
                ],
                TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: _req),
                const SizedBox(height: 14),
                TextFormField(
                  controller: pass,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) => (v ?? '').length < 6 ? 'At least 6 characters' : null,
                ),
                if (!signup) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: forgot, child: const Text('Forgot password?'))),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ivory))
                      : Text(signup ? 'Create account' : 'Log in'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => signup = !signup),
                  child: Text(signup ? 'Already registered? Log in' : 'New here? Create an account'),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  String? _req(String? v) => (v ?? '').trim().isEmpty ? 'Required' : null;
}

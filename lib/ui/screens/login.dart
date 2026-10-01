import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  bool register = false, obscure = true, busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> submit({bool demo = false}) async {
    if (busy || (!demo && !form.currentState!.validate())) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final repo = ref.read(repositoryProvider);
      if (demo) {
        await repo.signIn(Student.demo.email, 'local-demo');
      } else if (register) {
        await repo.register(name.text, email.text, password.text);
      } else {
        await repo.signIn(email.text, password.text);
      }
      ref.read(tabProvider.notifier).state = AppTab.find;
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> forgot() async {
    final controller = TextEditingController(text: email.text);
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Reset your password',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Campus email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Send reset link'),
          ),
        ],
      ),
    );
    if (selected != null && mounted) {
      try {
        await ref.read(repositoryProvider).resetPassword(selected);
        if (mounted) notify(context, 'Password reset email sent.');
      } catch (e) {
        if (mounted) notify(context, friendlyError(e));
      }
    }
    // Let the dialog finish its exit animation before disposing its text controller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(repositoryProvider).isDemo;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RoundButton(
                      'arrow-left',
                      label: 'Back to welcome',
                      background: AppColors.background,
                      onPressed: () =>
                          ref.read(onboardingProvider.notifier).showWelcome(),
                    ),
                    const Spacer(),
                    const Brand(size: 30),
                  ],
                ),
                const SizedBox(height: 42),
                AppIllustration(
                  register ? 'welcome_people' : 'good_company',
                  width: 200,
                  height: 120,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 24),
                Text(
                  register ? 'Meet your\ncampus people.' : 'Welcome\nback.',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 38,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  register
                      ? 'Create your account and make the next ride a shared one.'
                      : 'Sign in to find your next campus ride.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 32),
                if (register) ...[
                  TextFormField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      counterText: '',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(18),
                        child: AppIcon('user-round', size: 19),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().length < 2
                        ? 'Enter your full name.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  key: const ValueKey('login_email'),
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Campus email',
                    hintText: 'you@greenfield.edu',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(18),
                      child: AppIcon('mail', size: 19),
                    ),
                  ),
                  validator: (v) =>
                      v == null ||
                          !RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(v.trim())
                      ? 'Enter a valid campus email.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('login_password'),
                  controller: password,
                  obscureText: obscure,
                  autofillHints: [
                    register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'At least 6 characters',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(18),
                      child: AppIcon('lock-keyhole', size: 19),
                    ),
                    suffixIcon: IconButton(
                      tooltip: obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => obscure = !obscure),
                      icon: AppIcon(obscure ? 'eye' : 'eye-off', size: 19),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'Use at least 6 characters.'
                      : null,
                ),
                if (!register)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: forgot,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                if (register) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'By continuing, you agree to coordinate responsibly, use seat belts and respect other students’ privacy.',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                      height: 1.7,
                    ),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Surface(
                    color: AppColors.background,
                    radius: 14,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppIcon('triangle-alert', size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            error!,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                PrimaryButton(
                  register ? 'Create account' : 'Sign in',
                  onPressed: submit,
                  busy: busy,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      register
                          ? 'Already have an account?'
                          : 'New to RideTogether?',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              register = !register;
                              error = null;
                            }),
                      child: Text(register ? 'Sign in' : 'Create account'),
                    ),
                  ],
                ),
                if (demo) ...[
                  const Divider(),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: busy ? null : () => submit(demo: true),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon('graduation-cap', size: 19),
                          SizedBox(width: 9),
                          Text('Try the campus demo'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Local demo only. No real account or password is created.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, color: AppColors.muted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool busy = false;
  Future<void> action(bool resend) async {
    setState(() => busy = true);
    try {
      final r = ref.read(repositoryProvider);
      if (resend) {
        await r.resendVerification();
        if (mounted) notify(context, 'Verification email sent.');
      } else {
        await r.refreshUser();
        final refreshed = await r.watchSession().first;
        if (mounted && !(refreshed?.emailVerified ?? false)) {
          notify(context, 'Open the link in your inbox, then check again.');
        }
      }
    } catch (e) {
      if (mounted) notify(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Brand(),
            const Spacer(),
            const AppIcon('mail', size: 52),
            const SizedBox(height: 26),
            Text(
              'Check your\ncampus inbox.',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Text(
              'We sent a verification link to\n${ref.watch(currentStudentProvider)?.email ?? ''}.\nVerify your email before posting or reserving a ride.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.8,
              ),
            ),
            const Spacer(),
            PrimaryButton(
              'I’ve verified my email',
              onPressed: () => action(false),
              busy: busy,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: busy ? null : () => action(true),
                child: const Text('Resend email'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => ref.read(repositoryProvider).signOut(),
                child: const Text('Use another account'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

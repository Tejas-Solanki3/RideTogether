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
  bool register = false, hide = true, busy = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> _submit({bool demoQuick = false}) async {
    if (!demoQuick && !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final repo = ref.read(repositoryProvider);
      if (demoQuick) {
        await repo.signIn(Student.demo.email, 'demo123');
      } else if (register) {
        await repo.register(name.text, email.text, password.text);
      } else {
        await repo.signIn(email.text, password.text);
      }
    } catch (e) {
      if (mounted) notify(context, friendlyError(e), error: true);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(repositoryProvider).isDemo;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final large = c.maxWidth >= 950;
          final content = SingleChildScrollView(
            padding: const EdgeInsets.all(34),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Brand(),
                  const SizedBox(height: 46),
                  const Eyebrow('Your campus, connected.'),
                  const SizedBox(height: 12),
                  Text(
                    register
                        ? 'A better commute\nstarts with you.'
                        : 'Welcome to your\nbetter commute.',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    register
                        ? 'Join the journey with your campus email.'
                        : 'Sign in and find people heading your way.',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 28),
                  if (register) ...[
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Your name'),
                      validator: (v) => (v ?? '').trim().length < 2
                          ? 'Enter your name.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Campus email',
                      hintText: 'you@university.edu',
                    ),
                    validator: (v) =>
                        !RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch((v ?? '').trim())
                        ? 'Enter a valid campus email.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: password,
                    obscureText: hide,
                    autofillHints: [
                      register
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        tooltip: hide ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => hide = !hide),
                        icon: Icon(
                          hide
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 19,
                        ),
                      ),
                    ),
                    validator: (v) => (v ?? '').length < 6
                        ? 'Use at least 6 characters.'
                        : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (!register)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: busy
                            ? null
                            : () async {
                                if (email.text.trim().isEmpty) {
                                  notify(
                                    context,
                                    'Enter your campus email first.',
                                  );
                                  return;
                                }
                                try {
                                  await ref
                                      .read(repositoryProvider)
                                      .resetPassword(email.text);
                                  if (context.mounted) {
                                    notify(
                                      context,
                                      'If an account exists, a password reset email has been sent.',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    notify(
                                      context,
                                      friendlyError(e),
                                      error: true,
                                    );
                                  }
                                }
                              },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: register ? 'Create campus account' : 'Sign in',
                      onPressed: _submit,
                      loading: busy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() => register = !register),
                      child: Text(
                        register
                            ? 'Already part of the journey? Sign in'
                            : 'New here? Create an account',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  if (demo) ...[
                    const SizedBox(height: 20),
                    Surface(
                      color: AppColors.sage,
                      padding: const EdgeInsets.all(17),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Try the campus demo',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'This is local demo sign-in, not real authentication. No passwords are stored. Any 6+ character password works.',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.green,
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: 9),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => _submit(demoQuick: true),
                            child: const Text(
                              'Continue as Ishaan →',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  const Text(
                    'By continuing, travel responsibly and follow your campus carpool policies.',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          );
          if (!large) {
            return SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: content,
                ),
              ),
            );
          }
          return Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/campus_car.jpg',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.center,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xC918221C)],
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 42,
                          bottom: 47,
                          right: 42,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GO TOGETHER. GO BETTER.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 15),
                              Text(
                                'Your campus.\nConnected.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 50,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  letterSpacing: -2,
                                ),
                              ),
                              SizedBox(height: 18),
                              Text(
                                'Less traffic. More good company.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 500, child: Center(child: content)),
            ],
          );
        },
      ),
    );
  }
}

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final Student student;
  const VerifyEmailScreen({super.key, required this.student});
  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Surface(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Brand(),
                const SizedBox(height: 30),
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 48,
                  color: AppColors.green,
                ),
                const SizedBox(height: 22),
                Text(
                  'One small check.\nA safer campus.',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Verify the link sent to ${widget.student.email}. Then come back here to start sharing rides.',
                  style: const TextStyle(color: AppColors.muted, height: 1.8),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 27),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'I’ve verified my email',
                    loading: busy,
                    onPressed: () async {
                      setState(() => busy = true);
                      try {
                        await ref.read(repositoryProvider).refreshUser();
                        if (context.mounted &&
                            ref.read(currentStudentProvider)?.emailVerified !=
                                true) {
                          notify(
                            context,
                            'Your email isn’t verified yet. Open the link in your inbox first.',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          notify(context, friendlyError(e), error: true);
                        }
                      }
                      if (mounted) setState(() => busy = false);
                    },
                  ),
                ),
                const SizedBox(height: 9),
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          try {
                            await ref
                                .read(repositoryProvider)
                                .resendVerification();
                            if (context.mounted) {
                              notify(
                                context,
                                'Verification email sent. Check your spam folder too.',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              notify(context, friendlyError(e), error: true);
                            }
                          }
                        },
                  child: const Text('Resend verification link'),
                ),
                TextButton(
                  onPressed: () => ref.read(repositoryProvider).signOut(),
                  child: const Text('Use another account'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

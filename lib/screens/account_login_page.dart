import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../theme/portfolio_theme.dart';
import '../widgets/portfolio_components.dart';

class AccountLoginPage extends StatefulWidget {
  const AccountLoginPage({super.key, this.adminOnly = false});

  final bool adminOnly;

  @override
  State<AccountLoginPage> createState() => _AccountLoginPageState();
}

class _AccountLoginPageState extends State<AccountLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _creatingAccount = false;
  bool _hidePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = _creatingAccount
          ? await FirebaseService.auth.createUserWithEmailAndPassword(
              email: _email.text.trim(),
              password: _password.text,
            )
          : await FirebaseService.auth.signInWithEmailAndPassword(
              email: _email.text.trim(),
              password: _password.text,
            );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Authentication completed without a user account.',
        );
      }

      final isAdmin = await FirebaseService.hasAdminClaim(user);
      if (widget.adminOnly && !isAdmin) {
        await FirebaseService.auth.signOut();
        if (mounted) {
          setState(() {
            _error = 'This account does not have admin access. Sign in with your authorized administrator account.';
          });
        }
        return;
      }

      if (isAdmin && !_creatingAccount) {
        try {
          await FirebaseService.recordAdminActivity(
            action: 'Signed in',
            user: user,
          );
        } on FirebaseException catch (error) {
          if (mounted) {
            setState(() {
              _error =
                  'Signed in, but could not record login activity: '
                  '${error.message ?? error.code}';
            });
          }
          return;
        }
      }

      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(isAdmin ? '/admin' : '/', (route) => false);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message ?? 'Could not verify your account role.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _messageFor(FirebaseAuthException error) => switch (error.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Email or password is incorrect.',
    'email-already-in-use' => 'An account with this email already exists.',
    'weak-password' => 'Choose a stronger password with at least 6 characters.',
    'invalid-email' => 'Enter a valid email address.',
    'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
    'network-request-failed' =>
      'A network error occurred. Check your connection and retry.',
    'operation-not-allowed' =>
      'Email/password sign-in is not enabled in Firebase Authentication.',
    _ => error.message ?? 'Could not authenticate. Please try again.',
  };

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: PortfolioTheme.light,
      child: Scaffold(
        backgroundColor: PortfolioTheme.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: PortfolioCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.adminOnly
                              ? 'Admin sign in'
                              : _creatingAccount
                              ? 'Create your account'
                              : 'Welcome back',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          widget.adminOnly
                              ? 'Sign in with your authorized admin account.'
                              : 'Sign in or create an account to continue to irfandevs77.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: PortfolioTheme.muted,
                            fontSize: 13,
                          ),
                        ),
                        if (!widget.adminOnly) ...[
                          const SizedBox(height: 18),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text('Sign in'),
                                icon: Icon(Icons.login),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('Create account'),
                                icon: Icon(Icons.person_add_alt_1),
                              ),
                            ],
                            selected: {_creatingAccount},
                            onSelectionChanged: _loading
                                ? null
                                : (selection) => setState(() {
                                    _creatingAccount = selection.first;
                                    _error = null;
                                  }),
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'name@example.com',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (value) =>
                              value == null ||
                                  !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                      .hasMatch(value.trim())
                              ? 'Enter a valid email address.'
                              : null,
                        ),
                        const SizedBox(height: 13),
                        TextFormField(
                          controller: _password,
                          obscureText: _hidePassword,
                          autofillHints: [
                            _creatingAccount
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              tooltip: _hidePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your password.';
                            }
                            if (_creatingAccount && value.length < 6) {
                              return 'Use at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                        if (_creatingAccount) ...[
                          const SizedBox(height: 13),
                          TextFormField(
                            controller: _confirmPassword,
                            obscureText: _hidePassword,
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: Icon(Icons.lock_reset_outlined),
                            ),
                            validator: (value) => value != _password.text
                                ? 'Passwords do not match.'
                                : null,
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: const Color(0x1AF04F5F),
                              border: Border.all(
                                color: const Color(0x66D94352),
                              ),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFB42332),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 19),
                        GradientButton(
                          label: _loading
                              ? 'Please wait…'
                              : _creatingAccount
                              ? 'Create account'
                              : 'Sign in',
                          icon: _loading
                              ? Icons.hourglass_top
                              : Icons.arrow_forward,
                          onPressed: _loading ? () {} : _submit,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.of(context)
                                    .pushNamedAndRemoveUntil(
                                      '/',
                                      (route) => false,
                                    ),
                          child: const Text(
                            'Continue to irfandevs77',
                            style: TextStyle(color: PortfolioTheme.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.sendPasswordReset(email: _emailCtrl.text.trim());
    if (success && mounted) {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              const Color(0xFF0D2137),
              const Color(0xFF0A1628),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const SizedBox(height: 20),
                Text('Reset password', style: theme.textTheme.displayMedium),
                const SizedBox(height: 6),
                Text(
                  'Enter your email and we\'ll send you a reset link',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 40),
                if (_emailSent)
                  _buildSuccessState(theme)
                else
                  _buildForm(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              if (auth.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(auth.errorMessage!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error)),
                ),
              TextFormField(
                key: const Key('forgot_email'),
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.email,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('forgot_send_button'),
                onPressed: auth.isLoading ? null : _submit,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send Reset Email'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A).withAlpha(30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF16A34A).withAlpha(80)),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF16A34A), size: 48),
              const SizedBox(height: 12),
              Text('Email sent!',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: const Color(0xFF16A34A))),
              const SizedBox(height: 8),
              Text(
                'Check your inbox for the password reset link.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.textTheme.bodySmall?.color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          key: const Key('back_to_login'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }
}

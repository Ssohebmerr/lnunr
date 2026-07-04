import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_error_mapper.dart';
import '../../../core/privacy/consent_manager.dart';
import '../../../core/storage/user_prefs.dart';
import '../../../core/privacy/privacy_acceptance_row.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'auth_form_shell.dart';
import 'auth_navigation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _privacyAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/welcome');
    }
  }

  bool _requirePrivacy() {
    if (_privacyAccepted) return true;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.authPrivacyRequired)),
    );
    return false;
  }

  Future<void> _onAuthenticated() async {
    await ConsentManager.acceptPrivacyPolicy();
    if (!mounted) return;
    final root = Navigator.of(context, rootNavigator: true);
    if (root.canPop()) {
      completeAuthNavigation(context);
    } else {
      final done = await UserPrefs.isOnboardingDone();
      if (!mounted) return;
      context.go(done ? '/home' : '/onboarding');
    }
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (!_privacyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authPrivacyRequired)),
      );
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.registerFieldsRequired)),
      );
      return;
    }
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordMismatch)),
      );
      return;
    }
    context.read<AuthBloc>().add(SignUpRequested(email, password));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) _onAuthenticated();
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AuthErrorMapper.message(state.error, l10n),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;

        return AuthFormShell(
          icon: Icons.person_add_outlined,
          title: l10n.registerTitle,
          subtitle: l10n.registerSubtitle,
          onBack: _goBack,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!kIsWeb) ...[
                OutlinedButton.icon(
                  onPressed: loading
                      ? null
                      : () {
                          if (!_requirePrivacy()) return;
                          context.read<AuthBloc>().add(GoogleSignInRequested());
                        },
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(l10n.signInGoogle),
                  style: authSocialButtonStyle(context),
                ),
                if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                  const SizedBox(height: AppSpacing.sm + 4),
                  OutlinedButton.icon(
                    onPressed: loading
                        ? null
                        : () {
                            if (!_requirePrivacy()) return;
                            context.read<AuthBloc>().add(AppleSignInRequested());
                          },
                    icon: const Icon(Icons.apple, size: 22),
                    label: Text(l10n.signInApple),
                    style: authSocialButtonStyle(context),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg - 4),
                AuthOrDivider(label: l10n.authOrEmail),
                const SizedBox(height: AppSpacing.lg - 4),
              ],
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: AuraDecorations.glassInput(
                  isDark: isDark,
                  hint: l10n.email,
                  prefixIcon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _password,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                decoration: AuraDecorations.glassInput(
                  isDark: isDark,
                  hint: l10n.password,
                  prefixIcon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _confirm,
                obscureText: _obscureConfirm,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: AuraDecorations.glassInput(
                  isDark: isDark,
                  hint: l10n.confirmPassword,
                  prefixIcon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirm = !_obscureConfirm,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrivacyAcceptanceRow(
                accepted: _privacyAccepted,
                onChanged: (v) => setState(() => _privacyAccepted = v),
              ),
              const SizedBox(height: AppSpacing.md),
              AppGradientButton(
                label: loading ? l10n.loading : l10n.signUp,
                loading: loading,
                onPressed: loading ? null : _submit,
              ),
              AuthSecondaryLink(
                label: l10n.haveAccount,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        );
      },
    );
  }
}

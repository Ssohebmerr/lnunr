import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_error_mapper.dart';
import '../../../core/privacy/consent_manager.dart';
import '../../../core/privacy/privacy_acceptance_row.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'auth_form_shell.dart';
import 'auth_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _privacyAccepted = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
    final l10n = AppLocalizations.of(context)!;
    if (_privacyAccepted) return true;
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
      context.go('/home');
    }
  }

  void _submit() {
    if (!_requirePrivacy()) return;
    context.read<AuthBloc>().add(
          EmailSignInRequested(_email.text.trim(), _password.text.trim()),
        );
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
          icon: Icons.lock_outline,
          title: l10n.loginTitle,
          subtitle: l10n.loginSubtitle,
          onBack: _goBack,
          extraHeader: Text(
            l10n.signInOptionalSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
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
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
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
                label: loading ? l10n.loading : l10n.signIn,
                loading: loading,
                onPressed: loading ? null : _submit,
              ),
              if (!kIsWeb) ...[
                const SizedBox(height: AppSpacing.sm + 4),
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
              ],
              AuthSecondaryLink(
                label: l10n.noAccount,
                onPressed: () => context.go('/register'),
              ),
              TextButton(
                onPressed: () => context.go('/forgot-password'),
                child: Text(l10n.forgotPassword),
              ),
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(false);
                  } else {
                    context.go('/home');
                  }
                },
                child: Text(l10n.skipLogin),
              ),
            ],
          ),
        );
      },
    );
  }
}

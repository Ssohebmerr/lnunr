import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_error_mapper.dart';
import '../../../core/locale/locale_cubit.dart';
import '../../../core/privacy/consent_manager.dart';
import '../../../core/privacy/privacy_acceptance_row.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
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
    if (mounted) completeAuthNavigation(context);
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(false);
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: AppMeshBackground(
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
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
              return Stack(
                children: [
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: IconButton(
                      icon: const Icon(Icons.language),
                      onPressed: () => context.read<LocaleCubit>().toggle(),
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: AppGlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AuraDecorations.primaryGradient,
                                boxShadow: AppShadows.softRose(opacity: 0.25),
                              ),
                              child: const Icon(Icons.lock_outline,
                                  size: 32, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(l10n.loginTitle,
                                style: theme.textTheme.headlineSmall,
                                textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Text(l10n.loginSubtitle,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            Text(
                              l10n.signInOptionalSubtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: AuraDecorations.glassInput(
                                isDark: theme.brightness == Brightness.dark,
                                hint: l10n.email,
                                prefixIcon: Icons.email_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _password,
                              obscureText: true,
                              decoration: AuraDecorations.glassInput(
                                isDark: theme.brightness == Brightness.dark,
                                hint: l10n.password,
                                prefixIcon: Icons.lock_outline,
                              ),
                            ),
                            const SizedBox(height: 16),
                            PrivacyAcceptanceRow(
                              accepted: _privacyAccepted,
                              onChanged: (v) =>
                                  setState(() => _privacyAccepted = v),
                            ),
                            const SizedBox(height: 16),
                            AppGradientButton(
                              label: loading ? l10n.loading : l10n.signIn,
                              loading: loading,
                              onPressed: loading ? null : _submit,
                            ),
                            if (!kIsWeb) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: loading
                                    ? null
                                    : () {
                                        if (!_requirePrivacy()) return;
                                        context
                                            .read<AuthBloc>()
                                            .add(GoogleSignInRequested());
                                      },
                                icon: const Icon(Icons.g_mobiledata, size: 28),
                                label: Text(l10n.signInGoogle),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                              ),
                              if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: loading
                                      ? null
                                      : () {
                                          if (!_requirePrivacy()) return;
                                          context
                                              .read<AuthBloc>()
                                              .add(AppleSignInRequested());
                                        },
                                  icon: const Icon(Icons.apple, size: 22),
                                  label: Text(l10n.signInApple),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                ),
                              ],
                            ],
                            TextButton(
                              onPressed: () => openRegisterScreen(context),
                              child: Text(l10n.noAccount),
                            ),
                            TextButton(
                              onPressed: () => openForgotPasswordScreen(context),
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
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

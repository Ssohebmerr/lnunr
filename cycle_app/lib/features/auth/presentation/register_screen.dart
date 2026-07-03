import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_error_mapper.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/privacy/consent_manager.dart';
import '../../../core/privacy/privacy_acceptance_row.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _goBack() {
    final root = Navigator.of(context, rootNavigator: true);
    if (root.canPop()) {
      root.pop(false);
      return;
    }
    if (context.canPop()) {
      context.pop(false);
      return;
    }
    context.go('/home');
  }

  Future<void> _onAuthenticated() async {
    await ConsentManager.acceptPrivacyPolicy();
    if (mounted) completeAuthNavigation(context);
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
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
                      onPressed: () => context.read<LocaleController>().toggle(),
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
                              child: const Icon(Icons.person_add_outlined,
                                  size: 32, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(l10n.registerTitle,
                                style: theme.textTheme.headlineSmall,
                                textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Text(
                              l10n.loginSubtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
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
                            TextField(
                              controller: _confirm,
                              obscureText: true,
                              decoration: AuraDecorations.glassInput(
                                isDark: theme.brightness == Brightness.dark,
                                hint: l10n.confirmPassword,
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
                              label: loading ? l10n.loading : l10n.signUp,
                              loading: loading,
                              onPressed: loading ? null : _submit,
                            ),
                            TextButton(
                              onPressed: _goBack,
                              child: Text(l10n.haveAccount),
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

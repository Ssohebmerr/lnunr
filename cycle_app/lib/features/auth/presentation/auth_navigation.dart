import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'forgot_password_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Opens auth screens on the root navigator so they always appear above tabs.
Future<bool?> openLoginScreen(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
}

Future<bool?> openRegisterScreen(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(builder: (_) => const RegisterScreen()),
  );
}

Future<void> openForgotPasswordScreen(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
  );
}

/// After a successful sign-in/sign-up, return to the previous screen when
/// possible instead of resetting the whole app stack.
void completeAuthNavigation(BuildContext context) {
  final root = Navigator.of(context, rootNavigator: true);
  if (root.canPop()) {
    root.pop(true);
    return;
  }
  if (context.canPop()) {
    context.pop(true);
    return;
  }
  context.go('/home');
}

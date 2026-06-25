import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/premium/premium_status_notifier.dart';
import '../../../core/push/push_registration_service.dart';

import '../../../core/storage/user_prefs.dart';

import '../../cycle/data/cycle_sync_service.dart';

import '../data/auth_repository.dart';

import 'auth_event.dart';

import 'auth_state.dart';



class AuthBloc extends Bloc<AuthEvent, AuthState> {

  final AuthRepository authRepository;



  AuthBloc(this.authRepository) : super(AuthInitial()) {

    on<CheckAuthStatus>(_onCheck);

    on<EmailSignInRequested>(_onEmailSignIn);

    on<SignUpRequested>(_onSignUp);

    on<GoogleSignInRequested>(_onGoogle);

    on<AppleSignInRequested>(_onApple);

    on<ResetPasswordRequested>(_onReset);

    on<SignOutRequested>(_onSignOut);

  }



  Future<void> _runPostAuthTasks({String? signUpEmail}) async {

    final user = authRepository.currentUser;

    if (user == null) return;



    try {

      await UserPrefs.saveUid(user.uid);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({

        if (user.email != null && user.email!.isNotEmpty) 'email': user.email,

        'lastLoginAt': FieldValue.serverTimestamp(),

        if (signUpEmail != null) 'createdAt': FieldValue.serverTimestamp(),

      }, SetOptions(merge: true));

      await CycleSyncService().onAuthChanged(user);

      await PushRegistrationService().registerIfPossible();

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        await PremiumStatusNotifier.instance.applyRemote(
          userDoc.data()?['isPremium'] == true,
        );
      } catch (_) {}

    } catch (_) {

      // Auth succeeded — post-login sync is best-effort only.

    }

  }



  Future<void> _onCheck(CheckAuthStatus event, Emitter<AuthState> emit) async {

    final user = authRepository.currentUser;

    if (user != null) {

      await PushRegistrationService().registerIfPossible();

      unawaited(_syncPremiumFromFirestore(user.uid));

      emit(Authenticated(user));

    } else {

      emit(AuthInitial());

    }

  }

  Future<void> _syncPremiumFromFirestore(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      await PremiumStatusNotifier.instance.applyRemote(
        userDoc.data()?['isPremium'] == true,
      );
    } catch (_) {}
  }



  Future<void> _onEmailSignIn(

      EmailSignInRequested event, Emitter<AuthState> emit) async {

    emit(AuthLoading());

    try {

      await authRepository.signInWithEmail(event.email, event.password);

      final user = authRepository.currentUser!;

      emit(Authenticated(user));

      unawaited(_runPostAuthTasks());

    } catch (e) {

      emit(AuthError(e.toString()));

    }

  }



  Future<void> _onSignUp(SignUpRequested event, Emitter<AuthState> emit) async {

    emit(AuthLoading());

    try {

      await authRepository.signUpWithEmail(event.email, event.password);

      final user = authRepository.currentUser!;

      emit(Authenticated(user));

      unawaited(_runPostAuthTasks(signUpEmail: event.email));

    } catch (e) {

      emit(AuthError(e.toString()));

    }

  }



  Future<void> _onGoogle(

      GoogleSignInRequested event, Emitter<AuthState> emit) async {

    emit(AuthLoading());

    try {

      await authRepository.signInWithGoogle();

      final user = authRepository.currentUser!;

      emit(Authenticated(user));

      unawaited(_runPostAuthTasks());

    } catch (e) {

      emit(AuthError(e.toString()));

    }

  }



  Future<void> _onApple(

      AppleSignInRequested event, Emitter<AuthState> emit) async {

    emit(AuthLoading());

    try {

      await authRepository.signInWithApple();

      final user = authRepository.currentUser!;

      emit(Authenticated(user));

      unawaited(_runPostAuthTasks());

    } catch (e) {

      emit(AuthError(e.toString()));

    }

  }



  Future<void> _onReset(

      ResetPasswordRequested event, Emitter<AuthState> emit) async {

    emit(AuthLoading());

    try {

      await authRepository.sendPasswordResetEmail(event.email);

      emit(AuthPasswordResetSent());

    } catch (e) {

      emit(AuthError(e.toString()));

    }

  }



  Future<void> _onSignOut(SignOutRequested event, Emitter<AuthState> emit) async {

    await PushRegistrationService().clearToken();

    await authRepository.signOut();

    await UserPrefs.clearUid();

    await CycleSyncService().onAuthChanged(null);

    emit(AuthInitial());

  }

}


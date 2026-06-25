import 'package:flutter/material.dart';
import 'package:cycle_aura/menstrudel/database/repositories/user_repository.dart';
import 'package:cycle_aura/menstrudel/models/app/user_entry.dart';
import 'package:age_calculator/age_calculator.dart';
import 'package:cycle_aura/menstrudel/models/app/user_goal_types_enum.dart';
import 'package:cycle_aura/menstrudel/services/settings_service.dart';

/// This app does not have users in the sense of logins and cloud. 
/// In this case, a user is just the user of the app. 
/// This serivce just lets the app get date of birth, name, age etc.
class UserService extends ChangeNotifier {
  final UserRepository _userRepo;
  
  UserService(this._userRepo) {
    loadUser();
  }

  UserEntry? _user;
  bool _isLoading = false;
  int? _age;

  /// The user data.
  UserEntry? get user => _user;
  /// Whether service is loading
  bool get isLoading => _isLoading;
  /// The users age. If DoB is provided.
  int? get age => _age;

  /// Creates a default local profile when wellness features are opened for the first time.
  Future<bool> ensureDefaultUser(SettingsService settingsService) async {
    if (_user != null) return true;

    _isLoading = true;
    notifyListeners();

    try {
      final user = UserEntry(
        name: 'User',
        primaryGoal: UserGoalTypes.general,
      );
      await _userRepo.createUser(user);
      await settingsService.applySettingsForGoal(UserGoalTypes.general);
      _user = user;
      _age = null;
      return true;
    } catch (e) {
      debugPrint('UserService: ensureDefaultUser failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads user data.
  Future<void> loadUser() async {
    if (_isLoading) return;

    debugPrint('UserService: Starting loading user.');

    _isLoading = true;
    notifyListeners();

    _user = await _userRepo.getUser();

    if (_user != null && _user!.birthDate != null) {
      _age  = AgeCalculator.age(_user!.birthDate!).years;
    }else {
      _age = null;
    }

    _isLoading = false;    
    notifyListeners();
  }

  /// Updates the complete user.
  Future<void> updateUser(UserEntry user) async {
    _user = user;
    notifyListeners();
    _userRepo.updateUser(user);
  }

  /// Updates the user's date of birth.
  Future<void> setBirthDate(DateTime date) async {
    if (_user == null) return;
    _user = _user!.copyWith(birthDate: date);
    _age = AgeCalculator.age(_user!.birthDate!).years;
    notifyListeners();
    _userRepo.updateUser(_user!);
  }

  /// Remove date of birth.
  Future<void> removeBirthDate() async {
    if (_user == null) return;
    _user = _user!.copyWith(birthDate: null);
    notifyListeners();
    _userRepo.updateUser(_user!);
  }

  /// Updates the user's name
  Future<void> setName(String name) async {
    if (_user == null) return;
    _user = _user!.copyWith(name: name);
    notifyListeners();
    _userRepo.updateUser(_user!);
  }

  /// Updates the user's primary goal
  Future<void> setPrimaryGoal(UserGoalTypes goal, SettingsService settingsService) async {
    if (_user == null) return;
    _user = _user!.copyWith(primaryGoal: goal);
    notifyListeners();
    _userRepo.updateUser(_user!);
    settingsService.applySettingsForGoal(goal);
  }
}
import 'package:cycle_aura/menstrudel/database/repositories/logs_repository.dart';
import 'package:cycle_aura/menstrudel/database/repositories/pills_repository.dart';
import 'package:cycle_aura/menstrudel/database/repositories/reversible_contraceptive_repository.dart';
import 'package:cycle_aura/menstrudel/database/repositories/sanitary_product_repository.dart';
import 'package:cycle_aura/menstrudel/database/repositories/sex_repository.dart';
import 'package:cycle_aura/menstrudel/services/settings_service.dart';
import 'package:cycle_aura/menstrudel/services/symptom_service.dart';
import 'package:cycle_aura/menstrudel/services/user_service.dart';
import 'package:cycle_aura/menstrudel/services/wear_sync_service.dart';
import 'package:cycle_aura/menstrudel/database/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bootstraps Menstrudel services (separate SQLite DB from widget package).
class MenstrudelInit {
  MenstrudelInit._();

  static SharedPreferences? prefs;
  static SettingsService? settingsService;
  static UserService? userService;
  static SymptomService? symptomService;
  static WatchSyncService? watchService;
  static LogsRepository? logsRepository;
  static PillsRepository? pillsRepository;
  static SanitaryProductRepository? sanitaryRepository;
  static SexRepository? sexRepository;
  static ReversibleContraceptiveRepository? larcRepository;

  static Future<void> initialize() async {
    prefs = await SharedPreferences.getInstance();
    settingsService = SettingsService(prefs!);
    userService = UserService(UserRepository());
    symptomService = SymptomService(prefs!);
    logsRepository = LogsRepository();
    pillsRepository = PillsRepository();
    sanitaryRepository = SanitaryProductRepository();
    sexRepository = SexRepository();
    larcRepository = ReversibleContraceptiveRepository();
    watchService = WatchSyncService();
    watchService!.initialize(onPeriodLog: logsRepository!.logFromWatch);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/profile/local_profile.dart';
import '../../../core/storage/user_prefs.dart';

/// Optional patient identity shown at the top of the doctor report.
/// Stored locally only — never sent to the AI or any server.
class PatientInfo {
  const PatientInfo({this.name, this.age, this.note});

  final String? name;
  final int? age;
  final String? note;

  bool get hasName => name != null && name!.trim().isNotEmpty;
  bool get hasNote => note != null && note!.trim().isNotEmpty;

  bool get isEmpty => !hasName && age == null && !hasNote;

  PatientInfo copyWith({String? name, int? age, String? note}) => PatientInfo(
        name: name ?? this.name,
        age: age ?? this.age,
        note: note ?? this.note,
      );
}

/// Reads/writes the report-only patient overrides. Defaults fall back to the
/// app profile (display name + birth date) so the header is pre-filled without
/// ever mutating the real profile.
class DoctorReportPatientStore {
  DoctorReportPatientStore._();

  static const _nameKey = 'doctor_report_patient_name';
  static const _ageKey = 'doctor_report_patient_age';
  static const _noteKey = 'doctor_report_patient_note';

  static Future<PatientInfo> load() async {
    final prefs = await SharedPreferences.getInstance();

    var name = _clean(prefs.getString(_nameKey));
    if (name == null) {
      final profileName = (await LocalProfile.displayName()).trim();
      if (profileName.isNotEmpty && profileName != 'Guest') name = profileName;
    }

    int? age = prefs.getInt(_ageKey);
    if (age == null) {
      final dob = await UserPrefs.getProfileBirthDate();
      if (dob != null) age = _ageFrom(dob);
    }

    return PatientInfo(
      name: name,
      age: (age != null && age > 0 && age < 120) ? age : null,
      note: _clean(prefs.getString(_noteKey)),
    );
  }

  static Future<void> save(PatientInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await _set(prefs, _nameKey, info.name);
    if (info.age != null && info.age! > 0 && info.age! < 120) {
      await prefs.setInt(_ageKey, info.age!);
    } else {
      await prefs.remove(_ageKey);
    }
    await _set(prefs, _noteKey, info.note);
  }

  static Future<void> _set(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    final clean = _clean(value);
    if (clean == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, clean);
    }
  }

  static String? _clean(String? value) {
    final v = value?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  static int? _ageFrom(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return (age >= 0 && age < 120) ? age : null;
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'cycle_bridge_service.dart';

class LocalBackupService {
  LocalBackupService({CycleBridgeService? bridge})
    : _bridge = bridge ?? CycleBridgeService();

  final CycleBridgeService _bridge;

  Future<bool> exportAndShare() async {
    try {
      final backup = await _bridge.exportEncryptedBackup();
      final json = jsonEncode(backup);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cycle_aura_backup.json');
      await file.writeAsString(json);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Lune Backup'),
      );
      return true;
    } catch (e, st) {
      debugPrint('LocalBackupService.exportAndShare failed: $e\n$st');
      return false;
    }
  }

  Future<bool> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return false;

    try {
      final content = await File(result.files.single.path!).readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return false;
      return await _bridge.importEncryptedBackup(decoded);
    } catch (e, st) {
      debugPrint('LocalBackupService.importFromFile failed: $e\n$st');
      return false;
    }
  }
}

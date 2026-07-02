import 'package:flutter/foundation.dart';

/// Lets dialogs deep-link to a main tab (e.g. Account for Premium).
class HomeShellActions {
  HomeShellActions._();

  static void Function(int tabIndex)? switchTab;
  static VoidCallback? openLog;
  static VoidCallback? openAiChat;
  static VoidCallback? openReports;
  static VoidCallback? openReminders;
}

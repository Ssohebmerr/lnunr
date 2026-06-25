import 'package:flutter/foundation.dart';

/// Notifies [HomeTab] to reload cycle stats after logging or tab switch.
class HomeRefreshScope {
  HomeRefreshScope._();

  static final notifier = ValueNotifier<int>(0);

  static void refresh() => notifier.value++;
}

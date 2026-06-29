import 'package:flutter/material.dart';
import 'firebase_logger.dart';

class CrashlyticsNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName = route.settings.name ?? route.toString();
    FirebaseLogger.logMessage('NAV_PUSH: $routeName');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final routeName = route.settings.name ?? route.toString();
    FirebaseLogger.logMessage('NAV_POP: $routeName');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final oldName = oldRoute?.settings.name ?? oldRoute?.toString() ?? 'none';
    final newName = newRoute?.settings.name ?? newRoute?.toString() ?? 'none';
    FirebaseLogger.logMessage('NAV_REPLACE: $oldName -> $newName');
  }
}

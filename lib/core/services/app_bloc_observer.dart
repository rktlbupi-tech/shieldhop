import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'firebase_logger.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('BlocObserver: onError -- ${bloc.runtimeType}, $error');
    FirebaseLogger.recordError(
      error,
      stackTrace,
      reason: 'Uncaught error in ${bloc.runtimeType}',
    );
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);

    FirebaseLogger.logMessage(
      'BLOC_CHANGE: ${bloc.runtimeType} changed state from ${change.currentState.runtimeType} to ${change.nextState.runtimeType}',
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Custom BLoC observer for logging state changes
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    if (kDebugMode) {
      debugPrint('🟢 onCreate: ${bloc.runtimeType}');
    }
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    if (kDebugMode) {
      debugPrint('🔵 onEvent: ${bloc.runtimeType} - $event');
    }
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      debugPrint('🟡 onChange: ${bloc.runtimeType}');
      debugPrint('   Previous: ${change.currentState}');
      debugPrint('   Current: ${change.nextState}');
    }
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (kDebugMode) {
      debugPrint('🟣 onTransition: ${bloc.runtimeType}');
      debugPrint('   Event: ${transition.event}');
      debugPrint('   CurrentState: ${transition.currentState}');
      debugPrint('   NextState: ${transition.nextState}');
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (kDebugMode) {
      debugPrint('🔴 onError: ${bloc.runtimeType}');
      debugPrint('   Error: $error');
      debugPrint('   StackTrace: $stackTrace');
    }
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    if (kDebugMode) {
      debugPrint('⚫ onClose: ${bloc.runtimeType}');
    }
  }
}

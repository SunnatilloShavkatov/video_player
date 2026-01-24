import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

void logMessage(String message, {StackTrace? stackTrace, Object? error}) {
  if (kDebugMode) {
    developer.log('[Video Player]: $message', stackTrace: stackTrace, error: error);
  }
}

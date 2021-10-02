import 'dart:io';

import 'package:io/ansi.dart';

/// Infrastructure logger.
class Logger {
  /// Enable logging.
  final bool enableLogging;

  /// Create an [Logger].
  const Logger({this.enableLogging = false});

  /// Log a success action message.
  void logSuccess(String message) {
    if (enableLogging) {
      stdout.writeln(green.wrap(message));
    }
  }

  /// Log an information action message.
  void logInfo(String message) {
    if (enableLogging) {
      stdout.writeln(blue.wrap(message));
    }
  }

  /// Log an error action message.
  void logError(String message) {
    if (enableLogging) {
      stderr.writeln(red.wrap(message));
    }
  }
}

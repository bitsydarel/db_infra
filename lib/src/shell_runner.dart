import 'dart:convert';
import 'dart:io';

import 'package:bdlogging/bdlogging.dart';
import 'package:meta/meta.dart';

///
class ShellRunner {
  ///
  const ShellRunner({this.workingDirectory});

  ///
  final Directory? workingDirectory;

  ///
  Future<ShellOutput> executeAsync(
    String command,
    List<String> arguments, [
    Map<String, String>? environment,
  ]) async {
    final StringBuffer stdoutBuffer = StringBuffer();
    final StringBuffer stderrBuffer = StringBuffer();

    try {
      final Process process = await Process.start(
        command,
        arguments,
        runInShell: true,
        environment: environment,
        mode: ProcessStartMode.detachedWithStdio,
        workingDirectory: workingDirectory?.path,
      );

      final Future<void> stdoutFuture = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .map((String line) => line.trim())
          .where((String line) => line.isNotEmpty)
          .forEach(stdoutBuffer.writeln);

      final Future<void> stderrFuture = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .map((String line) => line.trim())
          .where((String line) => line.isNotEmpty)
          .forEach(stderrBuffer.writeln);

      await Future.wait(<Future<void>>[stdoutFuture, stderrFuture]);
    } on Object catch (e) {
      stderrBuffer.writeln('Error starting process: $e');
      BDLogger().error('Error starting process: $e', e);
    }

    return ShellOutput(
      stdout: stdoutBuffer.toString(),
      stderr: stdoutBuffer.toString(),
    );
  }

  ///
  ShellOutput execute(
    String command,
    List<String> arguments, [
    Map<String, String>? environment,
  ]) {
    final ProcessResult result = Process.runSync(
      command,
      arguments,
      runInShell: true,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
      environment: environment,
    );

    return ShellOutput(
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }
}

///
@immutable
class ShellOutput {
  ///
  final String stdout;

  ///
  final String stderr;

  ///
  const ShellOutput({required this.stdout, required this.stderr});

  ///
  String fullOutput() {
    return '${stdout.trim()}\n${stderr.trim()}';
  }

  ///
  bool isFailure() {
    final String trimmedStderr = stderr.trim().toLowerCase();
    final String trimmedStdout = stdout.trim().toLowerCase();

    // If stderr is empty, likely success
    if (trimmedStderr.isEmpty) {
      return false;
    }

    // Check if stdout indicates success despite stderr content
    final RegExp successPattern = RegExp(
      r'(?:^|\s)(success|succeeded|done|finished|ok)(?:\s|:|$)',
      caseSensitive: false,
    );

    if (successPattern.hasMatch(trimmedStdout)) {
      return false; // Success indicated in stdout
    }

    // Check stderr for actual errors
    final RegExp errorPattern = RegExp(
      r'(?:^|\s)(error|failed|failure|fatal)(?:\s|:|$)(?!.*(?:success|succeeded|complete|fix|resolve|handle))',
      caseSensitive: false,
    );

    return errorPattern.hasMatch(trimmedStderr);
  }

  ///
  bool contains(String pattern) {
    final String lowerCasePattern = pattern.toLowerCase();
    return stdout.toLowerCase().contains(lowerCasePattern) ||
        stderr.toLowerCase().contains(lowerCasePattern);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShellOutput &&
          runtimeType == other.runtimeType &&
          stdout == other.stdout &&
          stderr == other.stderr;

  @override
  int get hashCode => stdout.hashCode ^ stderr.hashCode;

  @override
  String toString() => 'ShellOutput{stdout: $stdout, stderr: $stderr}';
}

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
        mode: ProcessStartMode.detached,
        workingDirectory: workingDirectory?.path,
      );

      final Future<void> stdoutFuture = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach(stdoutBuffer.writeln);

      final Future<void> stderrFuture = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
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

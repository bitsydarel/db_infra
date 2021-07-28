import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

///
class ShellRunner {
  ///
  const ShellRunner();

  ///
  ShellOutput execute(String command, List<String> arguments) {
    final ProcessResult result = Process.runSync(
      command,
      arguments,
      runInShell: true,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
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

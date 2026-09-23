import 'dart:io';

/// Script to verify that test coverage in `coverage/lcov.info` is strictly 100.0%.
///
/// Usage: `dart run tool/verify_coverage.dart`
void main(List<String> args) {
  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    stderr.writeln(
      'Error: coverage/lcov.info not found. Run tests with coverage first:',
    );
    stderr.writeln('flutter test --coverage test/all_tests_coverage.dart');
    exit(1);
  }

  final lines = lcovFile.readAsLinesSync();
  final fileCoverage = <String, Map<int, int>>{};
  String? currentFile;

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('SF:')) {
      currentFile = trimmed.substring(3);
      fileCoverage.putIfAbsent(currentFile, () => {});
    } else if (trimmed.startsWith('DA:') && currentFile != null) {
      final parts = trimmed.substring(3).split(',');
      final lineNum = int.parse(parts[0]);
      final hits = int.parse(parts[1]);
      fileCoverage[currentFile]![lineNum] =
          (fileCoverage[currentFile]![lineNum] ?? 0) + hits;
    }
  }

  var totalLines = 0;
  var hitLines = 0;
  final uncoveredMap = <String, List<int>>{};

  for (final entry in fileCoverage.entries) {
    final f = entry.key;
    final lineHits = entry.value;
    final fTotal = lineHits.length;
    final fHit = lineHits.values.where((h) => h > 0).length;
    totalLines += fTotal;
    hitLines += fHit;

    final unhitLines = lineHits.entries
        .where((e) => e.value == 0)
        .map((e) => e.key)
        .toList();
    if (unhitLines.isNotEmpty) {
      uncoveredMap[f] = unhitLines;
    }
  }

  final percentage = totalLines == 0 ? 0.0 : (hitLines / totalLines) * 100;
  stdout.writeln('========================================================');
  stdout.writeln('                 LISTIX COVERAGE VERIFICATION           ');
  stdout.writeln('========================================================');
  stdout.writeln('Total Executable Lines : $totalLines');
  stdout.writeln('Total Lines Covered    : $hitLines');
  stdout.writeln('Coverage Percentage    : ${percentage.toStringAsFixed(2)}%');
  stdout.writeln('Files Evaluated        : ${fileCoverage.length}');
  stdout.writeln('========================================================');

  if (uncoveredMap.isNotEmpty || percentage < 100.0) {
    stderr.writeln('FAILURE: Codebase coverage is below 100.0%!');
    stderr.writeln('Uncovered files and lines:');
    for (final entry in uncoveredMap.entries) {
      stderr.writeln('  - ${entry.key}: lines ${entry.value}');
    }
    exit(1);
  } else {
    stdout.writeln(
      'SUCCESS: 100.00% TEST COVERAGE ACHIEVED ACROSS THE CODEBASE!',
    );
    exit(0);
  }
}

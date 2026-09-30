// CLI do gate de cobertura. Mesmo comando local e na CI:
//
//   dart run tool/coverage.dart prepare              # gera o teste all-imports
//   flutter test --coverage
//   dart run tool/coverage.dart clean                # remove o teste gerado
//   dart run tool/coverage.dart check --min=80       # aplica o limiar
//
// Opções do check: --lcov=coverage/lcov.info, --min=80, --worst=10.
// A lógica fica em coverage/coverage_gate.dart (testada em test/tool/).
import 'dart:io';

import 'coverage/coverage_gate.dart';

const _generatedTest = 'test/_coverage_all_imports_test.dart';

void main(List<String> args) {
  if (args.isEmpty) _usage();
  final options = _parseOptions(args.skip(1));

  switch (args.first) {
    case 'prepare':
      _prepare();
    case 'clean':
      _clean();
    case 'check':
      _check(options);
    default:
      _usage();
  }
}

void _prepare() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final packageName = RegExp(
    r'^name:\s*(\S+)',
    multiLine: true,
  ).firstMatch(pubspec)!.group(1)!;

  final libSources = {
    for (final entity in Directory('lib').listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.path.replaceAll(r'\', '/'): entity.readAsStringSync(),
  };

  File(_generatedTest).writeAsStringSync(
    buildAllImportsTest(packageName: packageName, libSources: libSources),
  );
  stdout.writeln('Gerado $_generatedTest (${libSources.length} arquivos).');
}

void _clean() {
  final file = File(_generatedTest);
  if (file.existsSync()) file.deleteSync();
}

void _check(Map<String, String> options) {
  final lcovPath = options['lcov'] ?? 'coverage/lcov.info';
  final minPercent = double.parse(options['min'] ?? '80');
  final worst = int.parse(options['worst'] ?? '10');

  final lcov = File(lcovPath);
  if (!lcov.existsSync()) {
    stderr.writeln(
      '$lcovPath não encontrado. Rode `flutter test --coverage` antes.',
    );
    exit(2);
  }

  final files = excludeFiles(
    parseLcov(lcov.readAsStringSync()),
    defaultCoverageExcludes,
  );
  final result = evaluateCoverage(files, minPercent: minPercent);

  stdout.write(formatReport(result, worst: worst));
  if (!result.passed) exit(1);
}

Map<String, String> _parseOptions(Iterable<String> args) {
  final options = <String, String>{};
  for (final arg in args) {
    final match = RegExp(r'^--([\w-]+)=(.*)$').firstMatch(arg);
    if (match == null) {
      stderr.writeln('Opção inválida: $arg (use --chave=valor)');
      exit(64);
    }
    options[match.group(1)!] = match.group(2)!;
  }
  return options;
}

Never _usage() {
  stderr.writeln(
    'Uso: dart run tool/coverage.dart <prepare|clean|check> '
    '[--lcov=coverage/lcov.info] [--min=80] [--worst=10]',
  );
  exit(64);
}

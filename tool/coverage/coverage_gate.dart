/// Lógica pura do gate de cobertura: parse do lcov, exclusões, limiar,
/// relatório e geração do teste que importa todo o `lib/`. Sem I/O — a CLI
/// (`tool/coverage.dart`) só lê/escreve arquivos e delega para cá.
library;

/// Padrões excluídos da cobertura por padrão: código gerado e entrypoints
/// (`runApp`), que não têm lógica a testar.
const List<String> defaultCoverageExcludes = [
  '**/*.g.dart',
  '**/*.freezed.dart',
  'lib/main.dart',
  'lib/main_*.dart',
];

class FileCoverage {
  const FileCoverage(
    this.path, {
    required this.linesFound,
    required this.linesHit,
  });

  final String path;
  final int linesFound;
  final int linesHit;

  double get percent => linesFound == 0 ? 100 : 100 * linesHit / linesFound;
}

/// Converte o conteúdo de um `lcov.info` em cobertura por arquivo.
///
/// Registros repetidos do mesmo arquivo são fundidos por número de linha
/// (a linha conta como coberta se algum registro a cobriu).
List<FileCoverage> parseLcov(String content) {
  final hitsByFile = <String, Map<int, int>>{};
  final summaryByFile = <String, (int, int)>{};

  String? current;
  var found = 0;
  var hit = 0;

  for (final raw in content.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('SF:')) {
      current = line.substring(3).replaceAll(r'\', '/');
      hitsByFile.putIfAbsent(current, () => {});
      found = 0;
      hit = 0;
    } else if (current == null) {
      continue;
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      final lineNumber = int.parse(parts[0]);
      final hits = int.parse(parts[1]);
      final lines = hitsByFile[current]!;
      final previous = lines[lineNumber] ?? 0;
      lines[lineNumber] = hits > previous ? hits : previous;
    } else if (line.startsWith('LF:')) {
      found = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hit = int.parse(line.substring(3));
    } else if (line == 'end_of_record') {
      final (prevFound, prevHit) = summaryByFile[current] ?? (0, 0);
      summaryByFile[current] = (prevFound + found, prevHit + hit);
      current = null;
    }
  }

  return [
    for (final MapEntry(key: path, value: lines) in hitsByFile.entries)
      if (lines.isNotEmpty)
        FileCoverage(
          path,
          linesFound: lines.length,
          linesHit: lines.values.where((h) => h > 0).length,
        )
      else
        FileCoverage(
          path,
          linesFound: summaryByFile[path]?.$1 ?? 0,
          linesHit: summaryByFile[path]?.$2 ?? 0,
        ),
  ];
}

/// Glob mínimo para caminhos com `/`: `**` atravessa diretórios (inclusive
/// nenhum), `*` e `?` ficam dentro de um segmento.
bool matchesGlob(String path, String glob) {
  final pattern = StringBuffer('^');
  for (var i = 0; i < glob.length; i++) {
    final char = glob[i];
    if (glob.startsWith('**/', i)) {
      pattern.write('(?:.*/)?');
      i += 2;
    } else if (glob.startsWith('**', i)) {
      pattern.write('.*');
      i += 1;
    } else if (char == '*') {
      pattern.write('[^/]*');
    } else if (char == '?') {
      pattern.write('[^/]');
    } else {
      pattern.write(RegExp.escape(char));
    }
  }
  pattern.write(r'$');
  return RegExp(pattern.toString()).hasMatch(path);
}

List<FileCoverage> excludeFiles(List<FileCoverage> files, List<String> globs) {
  return [
    for (final file in files)
      if (!globs.any((glob) => matchesGlob(file.path, glob))) file,
  ];
}

class CoverageResult {
  const CoverageResult({
    required this.linesFound,
    required this.linesHit,
    required this.minPercent,
    required this.worstFiles,
  });

  final int linesFound;
  final int linesHit;
  final double minPercent;

  /// Todos os arquivos, do menos para o mais coberto.
  final List<FileCoverage> worstFiles;

  double get percent => linesFound == 0 ? 0 : 100 * linesHit / linesFound;

  /// Sem nenhuma linha instrumentada o gate falha: é quase sempre um lcov
  /// vazio ou gerado no lugar errado, não um projeto 100% coberto.
  bool get passed => linesFound > 0 && percent >= minPercent;
}

CoverageResult evaluateCoverage(
  List<FileCoverage> files, {
  required double minPercent,
}) {
  final sorted = [...files]
    ..sort((a, b) {
      final byPercent = a.percent.compareTo(b.percent);
      return byPercent != 0 ? byPercent : a.path.compareTo(b.path);
    });

  return CoverageResult(
    linesFound: files.fold(0, (sum, f) => sum + f.linesFound),
    linesHit: files.fold(0, (sum, f) => sum + f.linesHit),
    minPercent: minPercent,
    worstFiles: sorted,
  );
}

String formatReport(CoverageResult result, {int worst = 10}) {
  final buffer = StringBuffer()
    ..writeln(
      'Cobertura: ${result.percent.toStringAsFixed(2)}% '
      '(${result.linesHit}/${result.linesFound} linhas) — '
      'limiar ${result.minPercent.toStringAsFixed(2)}% → '
      '${result.passed ? 'OK' : 'FALHOU'}',
    );

  final shown = result.worstFiles.take(worst).toList();
  if (shown.isNotEmpty) {
    buffer.writeln('Arquivos menos cobertos:');
    for (final file in shown) {
      buffer.writeln(
        '  ${file.percent.toStringAsFixed(1).padLeft(5)}%  '
        '${'${file.linesHit}/${file.linesFound}'.padLeft(9)}  ${file.path}',
      );
    }
  }
  return buffer.toString();
}

/// Gera um teste que importa todo arquivo de `lib/`. Sem ele, arquivos que
/// nenhum teste importa nem aparecem no lcov — e ficam fora do cálculo, em
/// vez de contar como 0%.
String buildAllImportsTest({
  required String packageName,
  required Map<String, String> libSources,
}) {
  final partOf = RegExp(r'^\s*part\s+of\b', multiLine: true);
  final paths =
      libSources.entries
          .where((e) => e.key.startsWith('lib/') && e.key.endsWith('.dart'))
          .where((e) => !partOf.hasMatch(e.value))
          .map((e) => e.key.substring('lib/'.length))
          .toList()
        ..sort();

  final buffer = StringBuffer()
    ..writeln('// GERADO por `dart run tool/coverage.dart prepare`. Não edite.')
    ..writeln('// ignore_for_file: unused_import, directives_ordering')
    ..writeln()
    ..writeln("import 'package:flutter_test/flutter_test.dart';")
    ..writeln();
  for (final (index, path) in paths.indexed) {
    buffer.writeln("import 'package:$packageName/$path' as i$index;");
  }
  buffer
    ..writeln()
    ..writeln('void main() {')
    ..writeln(
      "  test('carrega todo o lib/ para a cobertura contar arquivos sem teste', () {});",
    )
    ..writeln('}');
  return buffer.toString();
}

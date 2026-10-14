import 'package:flutter_test/flutter_test.dart';

import '../../tool/coverage/coverage_gate.dart';

void main() {
  group('parseLcov', () {
    test('lê linhas encontradas e cobertas a partir dos registros DA', () {
      const lcov = '''
SF:lib/a.dart
DA:1,1
DA:2,0
DA:3,4
LF:3
LH:2
end_of_record
SF:lib/b.dart
DA:10,0
end_of_record
''';

      final files = parseLcov(lcov);

      expect(files, hasLength(2));
      expect(files[0].path, 'lib/a.dart');
      expect(files[0].linesFound, 3);
      expect(files[0].linesHit, 2);
      expect(files[1].path, 'lib/b.dart');
      expect(files[1].linesFound, 1);
      expect(files[1].linesHit, 0);
    });

    test('usa LF/LH quando o registro não traz DA', () {
      const lcov = 'SF:lib/a.dart\nLF:10\nLH:7\nend_of_record\n';

      final file = parseLcov(lcov).single;

      expect(file.linesFound, 10);
      expect(file.linesHit, 7);
    });

    test('funde registros repetidos do mesmo arquivo pela linha', () {
      // Uma linha coberta em qualquer registro conta como coberta uma vez.
      const lcov = '''
SF:lib/a.dart
DA:1,0
DA:2,1
end_of_record
SF:lib/a.dart
DA:1,3
DA:2,0
DA:3,0
end_of_record
''';

      final file = parseLcov(lcov).single;

      expect(file.linesFound, 3);
      expect(file.linesHit, 2);
    });

    test('normaliza separador do Windows e ignora linhas em branco', () {
      const lcov = 'SF:lib\\core\\a.dart\r\nDA:1,1\r\n\r\nend_of_record\r\n';

      expect(parseLcov(lcov).single.path, 'lib/core/a.dart');
    });

    test('lcov vazio resulta em lista vazia', () {
      expect(parseLcov(''), isEmpty);
    });
  });

  group('matchesGlob', () {
    test('** casa qualquer profundidade, inclusive zero', () {
      expect(matchesGlob('lib/a.g.dart', '**/*.g.dart'), isTrue);
      expect(matchesGlob('lib/x/y/a.g.dart', '**/*.g.dart'), isTrue);
      expect(matchesGlob('a.g.dart', '**/*.g.dart'), isTrue);
      expect(matchesGlob('lib/a.dart', '**/*.g.dart'), isFalse);
    });

    test('* não atravessa diretórios', () {
      expect(matchesGlob('lib/main_dev.dart', 'lib/main_*.dart'), isTrue);
      expect(matchesGlob('lib/x/main_dev.dart', 'lib/main_*.dart'), isFalse);
    });

    test('pontos são literais, não curingas de regex', () {
      expect(matchesGlob('lib/mainXdart', 'lib/main.dart'), isFalse);
      expect(matchesGlob('lib/main.dart', 'lib/main.dart'), isTrue);
    });

    test('? casa exatamente um caractere', () {
      expect(matchesGlob('lib/a1.dart', 'lib/a?.dart'), isTrue);
      expect(matchesGlob('lib/a12.dart', 'lib/a?.dart'), isFalse);
    });
  });

  group('excludeFiles', () {
    test('remove arquivos que casam com qualquer padrão', () {
      final files = [
        const FileCoverage('lib/a.dart', linesFound: 1, linesHit: 1),
        const FileCoverage('lib/a.g.dart', linesFound: 9, linesHit: 0),
        const FileCoverage('lib/b.freezed.dart', linesFound: 9, linesHit: 0),
        const FileCoverage('lib/main_dev.dart', linesFound: 3, linesHit: 0),
      ];

      final kept = excludeFiles(files, defaultCoverageExcludes);

      expect(kept.map((f) => f.path), ['lib/a.dart']);
    });
  });

  group('evaluateCoverage', () {
    const files = [
      FileCoverage('lib/good.dart', linesFound: 10, linesHit: 10),
      FileCoverage('lib/bad.dart', linesFound: 10, linesHit: 5),
      FileCoverage('lib/zero.dart', linesFound: 5, linesHit: 0),
    ];

    test('agrega o percentual sobre todas as linhas', () {
      final result = evaluateCoverage(files, minPercent: 50);

      expect(result.linesFound, 25);
      expect(result.linesHit, 15);
      expect(result.percent, closeTo(60, 0.001));
    });

    test('passa quando atinge exatamente o limiar', () {
      expect(evaluateCoverage(files, minPercent: 60).passed, isTrue);
    });

    test('falha abaixo do limiar', () {
      expect(evaluateCoverage(files, minPercent: 80).passed, isFalse);
    });

    test('ordena os piores arquivos primeiro', () {
      final result = evaluateCoverage(files, minPercent: 80);

      expect(result.worstFiles.map((f) => f.path), [
        'lib/zero.dart',
        'lib/bad.dart',
        'lib/good.dart',
      ]);
    });

    test('sem linhas instrumentadas falha: sinal de lcov vazio ou errado', () {
      final result = evaluateCoverage(const [], minPercent: 80);

      expect(result.passed, isFalse);
      expect(result.linesFound, 0);
    });
  });

  group('formatReport', () {
    test('resume total, limiar, veredito e os piores arquivos', () {
      const files = [
        FileCoverage('lib/good.dart', linesFound: 10, linesHit: 10),
        FileCoverage('lib/bad.dart', linesFound: 10, linesHit: 5),
      ];
      final report = formatReport(
        evaluateCoverage(files, minPercent: 80),
        worst: 1,
      );

      expect(report, contains('75.00%'));
      expect(report, contains('80.00%'));
      expect(report, contains('FALHOU'));
      expect(report, contains('lib/bad.dart'));
      expect(report, isNot(contains('lib/good.dart')));
    });

    test('indica sucesso quando passa', () {
      const files = [FileCoverage('lib/a.dart', linesFound: 4, linesHit: 4)];

      expect(
        formatReport(evaluateCoverage(files, minPercent: 80)),
        contains('OK'),
      );
    });
  });

  group('buildAllImportsTest', () {
    test('importa cada arquivo de lib com prefixo próprio', () {
      final source = buildAllImportsTest(
        packageName: 'autouni_app',
        libSources: {
          'lib/b.dart': 'class B {}',
          'lib/core/a.dart': 'void a() {}',
        },
      );

      expect(source, contains("import 'package:autouni_app/b.dart' as i0;"));
      expect(
        source,
        contains("import 'package:autouni_app/core/a.dart' as i1;"),
      );
      expect(source, contains('void main()'));
    });

    test('ordena os imports para gerar saída estável', () {
      final source = buildAllImportsTest(
        packageName: 'p',
        libSources: {'lib/z.dart': '', 'lib/a.dart': ''},
      );

      expect(
        source.indexOf('package:p/a.dart'),
        lessThan(source.indexOf('package:p/z.dart')),
      );
    });

    test('pula arquivos "part of" (não podem ser importados)', () {
      final source = buildAllImportsTest(
        packageName: 'p',
        libSources: {
          'lib/model.dart': "part 'model.g.dart';",
          'lib/model.g.dart': "part of 'model.dart';",
        },
      );

      expect(source, contains('package:p/model.dart'));
      expect(source, isNot(contains('model.g.dart')));
    });

    test('ignora o que não for .dart dentro de lib', () {
      final source = buildAllImportsTest(
        packageName: 'p',
        libSources: {'lib/README.md': '# doc', 'lib/a.dart': ''},
      );

      expect(source, isNot(contains('README')));
    });
  });
}

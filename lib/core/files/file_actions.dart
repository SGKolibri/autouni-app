import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Resultado de tentar abrir um arquivo num visualizador do aparelho.
enum FileOpenResult {
  opened,

  /// Nenhum app instalado abre esse tipo (ex.: XLSX sem planilha).
  noApp,
  failed,
}

/// Arquivos baixados pelo app: guardar, abrir num visualizador e
/// compartilhar. Isola `path_provider`, `open_filex` e `share_plus` do resto
/// do código (e dos testes).
abstract interface class FileActions {
  /// Grava [bytes] numa pasta temporária do app e devolve o caminho. O
  /// sistema pode limpar essa pasta; quem precisa do arquivo guarda o
  /// caminho só enquanto ele existir ([exists]).
  Future<String> saveTemporary(String fileName, List<int> bytes);

  Future<bool> exists(String path);

  Future<FileOpenResult> open(String path, {required String mimeType});

  /// Abre a share sheet do sistema com o arquivo.
  Future<void> share(String path, {required String mimeType, String? subject});
}

class PlatformFileActions implements FileActions {
  const PlatformFileActions();

  @override
  Future<String> saveTemporary(String fileName, List<int> bytes) async {
    final base = await getTemporaryDirectory();
    final folder = Directory('${base.path}/reports');
    await folder.create(recursive: true);
    final file = File('${folder.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<bool> exists(String path) => File(path).exists();

  @override
  Future<FileOpenResult> open(String path, {required String mimeType}) async {
    final result = await OpenFilex.open(path, type: mimeType);
    return switch (result.type) {
      ResultType.done => FileOpenResult.opened,
      ResultType.noAppToOpen => FileOpenResult.noApp,
      _ => FileOpenResult.failed,
    };
  }

  @override
  Future<void> share(
    String path, {
    required String mimeType,
    String? subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: mimeType)],
        subject: subject,
      ),
    );
  }
}

final fileActionsProvider = Provider<FileActions>(
  (ref) => const PlatformFileActions(),
  name: 'fileActionsProvider',
);

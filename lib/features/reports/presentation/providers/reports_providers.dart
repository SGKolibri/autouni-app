import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/cached.dart';
import '../../../../core/files/file_actions.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/session/session_hooks.dart';
import '../../../../shared/models/campus/campus_models.dart';
import '../../../../shared/rbac/app_permission.dart';
import '../../../../shared/rbac/rbac_providers.dart';
import '../../data/reports_repository.dart';
import '../../domain/report_models.dart';
import '../../domain/report_request.dart';

/// Relatórios do usuário. Enquanto algum estiver na fila ou gerando, a lista
/// se atualiza sozinha a cada [pollInterval] (o backend não avisa pelo
/// WebSocket; o push chega só no fim).
class MyReports extends StreamNotifier<Cached<List<Report>>> {
  static const Duration pollInterval = Duration(seconds: 4);

  /// Teto da espera entre tentativas quando a rede falha.
  static const Duration maxPollInterval = Duration(seconds: 30);

  Timer? _poll;

  @override
  Stream<Cached<List<Report>>> build() {
    ref.watch(sessionUserIdProvider);
    ref.onDispose(() => _poll?.cancel());
    return ref.watch(reportsRepositoryProvider).watchMine().map((cached) {
      _schedule(cached.data);
      return cached;
    });
  }

  /// Coloca [report] (recém-criado) no topo e começa a acompanhar.
  void add(Report report) {
    final current = state.value?.data ?? const <Report>[];
    final next = [report, ...current.where((r) => r.id != report.id)];
    state = AsyncData(Cached(next));
    _schedule(next);
  }

  void _schedule(List<Report> reports, [Duration delay = pollInterval]) {
    _poll?.cancel();
    if (!reports.any((report) => report.status.inProgress)) return;
    _poll = Timer(delay, () => _refresh(delay));
  }

  Future<void> _refresh(Duration lastDelay) async {
    try {
      final fresh = await ref.read(reportsRepositoryProvider).fetchMine();
      if (!ref.mounted) return;
      state = AsyncData(Cached(fresh));
      _schedule(fresh);
    } on ApiException {
      if (!ref.mounted) return;
      // Sem rede: tenta de novo, cada vez mais devagar.
      final next = lastDelay * 2;
      _schedule(
        state.value?.data ?? const [],
        next > maxPollInterval ? maxPollInterval : next,
      );
    }
  }
}

final myReportsProvider =
    StreamNotifierProvider.autoDispose<MyReports, Cached<List<Report>>>(
      MyReports.new,
      name: 'myReportsProvider',
    );

/// Um relatório por id: da lista, quando já está nela (e acompanha a
/// geração junto); senão, buscado na API (deep link de notificação).
final reportProvider = FutureProvider.autoDispose.family<Report, String>((
  ref,
  id,
) async {
  // Espera a lista (cache ou rede) antes de decidir, para não buscar à toa.
  List<Report> list;
  try {
    list = (await ref.watch(myReportsProvider.future)).data;
  } on Object {
    list = const [];
  }
  for (final report in list) {
    if (report.id == id) return report;
  }
  final report = await ref.watch(reportsRepositoryProvider).fetch(id);
  if (report.status.inProgress) {
    // Fora da lista, ninguém acompanha: consulta de novo daqui a pouco.
    final timer = Timer(MyReports.pollInterval, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return report;
}, name: 'reportProvider');

/// Prédios do filtro de localização.
final reportBuildingsProvider = FutureProvider.autoDispose<List<Building>>(
  (ref) => ref.watch(reportsRepositoryProvider).buildings(),
  name: 'reportBuildingsProvider',
);

/// Arquivos já baixados nesta sessão e downloads em andamento.
@immutable
class ReportFiles {
  const ReportFiles({this.paths = const {}, this.downloading = const {}});

  /// id do relatório → caminho no aparelho.
  final Map<String, String> paths;
  final Set<String> downloading;

  bool isDownloading(String id) => downloading.contains(id);
}

class ReportFilesNotifier extends Notifier<ReportFiles> {
  @override
  ReportFiles build() {
    ref.watch(sessionUserIdProvider);
    return const ReportFiles();
  }

  void started(String id) => state = ReportFiles(
    paths: state.paths,
    downloading: {...state.downloading, id},
  );

  void finished(String id, {String? path}) => state = ReportFiles(
    paths: path == null ? state.paths : {...state.paths, id: path},
    downloading: {...state.downloading}..remove(id),
  );

  void forget(String id) => state = ReportFiles(
    paths: {...state.paths}..remove(id),
    downloading: state.downloading,
  );
}

final reportFilesProvider = NotifierProvider<ReportFilesNotifier, ReportFiles>(
  ReportFilesNotifier.new,
  name: 'reportFilesProvider',
);

/// Resultado de pedir um relatório.
class CreateReportOutcome {
  const CreateReportOutcome.created(Report this.report)
    : errors = const {},
      message = null;

  const CreateReportOutcome.invalid(this.errors)
    : report = null,
      message = null;

  const CreateReportOutcome.failed(String this.message)
    : report = null,
      errors = const {};

  final Report? report;

  /// Erros por campo do formulário.
  final Map<String, String> errors;
  final String? message;

  bool get isCreated => report != null;
}

/// Ações sobre relatórios. Os métodos de arquivo devolvem a mensagem para o
/// usuário, ou `null` em sucesso.
class ReportsController {
  ReportsController(this._ref, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Ref _ref;
  final DateTime Function() _now;

  ReportsRepository get _repository => _ref.read(reportsRepositoryProvider);
  FileActions get _files => _ref.read(fileActionsProvider);
  ReportFilesNotifier get _downloads => _ref.read(reportFilesProvider.notifier);

  Future<CreateReportOutcome> create(ReportRequest request) async {
    if (!_ref.read(hasPermissionProvider(AppPermission.generateReports))) {
      return const CreateReportOutcome.failed(
        'Seu perfil não permite gerar relatórios.',
      );
    }
    final errors = request.validate(today: _now());
    if (errors.isNotEmpty) return CreateReportOutcome.invalid(errors);
    try {
      final report = await _repository.create(request);
      _ref.read(myReportsProvider.notifier).add(report);
      return CreateReportOutcome.created(report);
    } on ApiException catch (error) {
      return CreateReportOutcome.failed(error.message);
    }
  }

  /// Gera de novo com os mesmos parâmetros (relatório que falhou).
  Future<CreateReportOutcome> retry(Report report) =>
      create(ReportRequest.fromReport(report));

  /// Baixa (se ainda não baixou) e abre num visualizador do aparelho.
  Future<String?> open(Report report) async {
    final (path, error) = await _fileFor(report);
    if (path == null) return error;
    final result = await _files.open(path, mimeType: report.format.mimeType);
    return switch (result) {
      FileOpenResult.opened => null,
      FileOpenResult.noApp =>
        'Nenhum app instalado abre arquivos ${report.format.label}. '
            'Use "Compartilhar" para enviar a outro app.',
      FileOpenResult.failed => 'Não foi possível abrir o arquivo.',
    };
  }

  /// Baixa (se ainda não baixou) e abre a share sheet do sistema.
  Future<String?> share(Report report) async {
    final (path, error) = await _fileFor(report);
    if (path == null) return error;
    try {
      await _files.share(
        path,
        mimeType: report.format.mimeType,
        subject: report.title,
      );
      return null;
    } on Exception {
      return 'Não foi possível compartilhar o arquivo.';
    }
  }

  Future<(String?, String?)> _fileFor(Report report) async {
    if (!report.canDownload) {
      return (null, 'O relatório ainda não está pronto.');
    }
    final state = _ref.read(reportFilesProvider);
    if (state.isDownloading(report.id)) return (null, null);
    final known = state.paths[report.id];
    if (known != null && await _files.exists(known)) return (known, null);

    _downloads.started(report.id);
    try {
      final file = await _repository.download(report.id);
      final path = await _files.saveTemporary(report.fileName, file.bytes);
      _downloads.finished(report.id, path: path);
      return (path, null);
    } on ApiException catch (error) {
      _downloads.finished(report.id);
      return (null, 'Não foi possível baixar: ${error.message}');
    } on Exception {
      _downloads.finished(report.id);
      return (null, 'Não foi possível salvar o arquivo no aparelho.');
    }
  }
}

final reportsControllerProvider = Provider<ReportsController>(
  ReportsController.new,
  name: 'reportsControllerProvider',
);

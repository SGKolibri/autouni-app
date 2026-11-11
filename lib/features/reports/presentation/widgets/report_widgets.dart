import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/rbac/app_permission.dart';
import '../../../../shared/rbac/rbac_providers.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/report_models.dart';
import '../providers/reports_providers.dart';

IconData reportFormatIcon(ReportFormat format) => switch (format) {
  ReportFormat.pdf => Icons.picture_as_pdf_outlined,
  ReportFormat.csv => Icons.table_rows_outlined,
  ReportFormat.xlsx => Icons.grid_on_outlined,
};

/// Pílula do andamento da geração.
class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({required this.status, super.key});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = switch (status) {
      ReportStatus.pending => (AppTone.neutral, Icons.schedule),
      ReportStatus.processing => (AppTone.info, Icons.autorenew),
      ReportStatus.completed => (AppTone.success, Icons.check_circle_outline),
      ReportStatus.failed => (AppTone.danger, Icons.error_outline),
    };
    return StatusBadge(
      status.label,
      key: ValueKey('report-status-${status.name}'),
      tone: tone,
      icon: icon,
      dense: true,
    );
  }
}

/// Mostra [message] num snackbar, se houver.
void showReportMessage(ScaffoldMessengerState messenger, String? message) {
  if (message == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Ações do relatório conforme o status: abrir/compartilhar quando pronto,
/// "Gerar de novo" quando falhou.
class ReportActions extends ConsumerWidget {
  const ReportActions({required this.report, this.expanded = false, super.key});

  final Report report;

  /// Botões grandes com rótulo (detalhe) em vez de ícones (lista).
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(reportsControllerProvider);
    final downloading = ref.watch(
      reportFilesProvider.select((files) => files.isDownloading(report.id)),
    );

    if (report.canDownload) {
      if (downloading) {
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              semanticsLabel: 'Baixando relatório',
            ),
          ),
        );
      }
      final messenger = ScaffoldMessenger.of(context);
      Future<void> open() async =>
          showReportMessage(messenger, await controller.open(report));
      Future<void> share() async =>
          showReportMessage(messenger, await controller.share(report));
      if (expanded) {
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('report-open'),
                onPressed: open,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('report-share'),
                onPressed: share,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Compartilhar'),
              ),
            ),
          ],
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('report-open-${report.id}'),
            tooltip: 'Abrir',
            onPressed: open,
            icon: const Icon(Icons.open_in_new),
          ),
          IconButton(
            key: ValueKey('report-share-${report.id}'),
            tooltip: 'Compartilhar',
            onPressed: share,
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      );
    }

    if (report.status == ReportStatus.failed &&
        ref.watch(hasPermissionProvider(AppPermission.generateReports))) {
      final messenger = ScaffoldMessenger.of(context);
      Future<void> retry() async {
        final outcome = await controller.retry(report);
        showReportMessage(
          messenger,
          outcome.isCreated
              ? 'Relatório na fila de novo.'
              : outcome.message ?? outcome.errors.values.first,
        );
      }

      return expanded
          ? FilledButton.icon(
              key: const Key('report-retry'),
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Gerar de novo'),
            )
          : IconButton(
              key: ValueKey('report-retry-${report.id}'),
              tooltip: 'Gerar de novo',
              onPressed: retry,
              icon: const Icon(Icons.refresh),
            );
    }
    return const SizedBox.shrink();
  }
}

/// Linha da lista de relatórios.
class ReportTile extends StatelessWidget {
  const ReportTile({required this.report, required this.onTap, super.key});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = report.createdAt;
    return ListTile(
      onTap: onTap,
      leading: Icon(
        reportFormatIcon(report.format),
        color: theme.colorScheme.primary,
        semanticLabel: report.format.label,
      ),
      title: Text(report.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ReportStatusBadge(status: report.status),
            Text(
              [
                report.type.label,
                if (createdAt != null) formatClock(createdAt),
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      trailing: ReportActions(report: report),
    );
  }
}

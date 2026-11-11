import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/utils/error_messages.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/report_models.dart';
import '../../domain/report_request.dart';
import '../providers/reports_providers.dart';
import '../widgets/report_widgets.dart';

/// Um relatório: parâmetros, andamento e abrir/compartilhar. Destino do
/// alerta "Relatório gerado" (`/reports/<id>`).
class ReportDetailPage extends ConsumerWidget {
  const ReportDetailPage({required this.reportId, super.key});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider(reportId));
    return Scaffold(
      appBar: AppTopBar(title: report.value?.title ?? 'Relatório'),
      body: switch (report) {
        AsyncValue(:final value?) => _ReportDetail(report: value),
        AsyncValue(:final error?) => AppErrorState(
          message: describeError(error),
          onRetry: () => ref.invalidate(reportProvider(reportId)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ReportDetail extends ConsumerWidget {
  const _ReportDetail({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final period = ReportRequest.fromReport(report).period;
    final buildingId = report.filters['buildingId'];
    final buildingName = buildingId is String
        ? ref
              .watch(reportBuildingsProvider)
              .value
              ?.where((b) => b.id == buildingId)
              .firstOrNull
              ?.name
        : null;
    final createdAt = report.createdAt;

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Icon(
              reportFormatIcon(report.format),
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            ReportStatusBadge(status: report.status),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(report.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        row('Tipo', report.type.label),
        row('Formato', report.format.label),
        if (report.type.usesPeriod)
          row('Período', period?.label ?? 'Todo o histórico'),
        row(
          'Local',
          buildingId is String ? buildingName ?? 'Um prédio' : 'Campus inteiro',
        ),
        if (createdAt != null) row('Pedido em', formatDateTime(createdAt)),
        const SizedBox(height: AppSpacing.xl),
        switch (report.status) {
          ReportStatus.pending || ReportStatus.processing => const AppBanner(
            tone: AppTone.info,
            icon: Icons.autorenew,
            message:
                'Gerando o arquivo. Esta tela atualiza sozinha e você recebe '
                'um alerta quando ficar pronto.',
          ),
          ReportStatus.failed => const AppBanner(
            tone: AppTone.danger,
            message: 'A geração falhou. Tente gerar de novo.',
          ),
          ReportStatus.completed => const SizedBox.shrink(),
        },
        const SizedBox(height: AppSpacing.lg),
        ReportActions(report: report, expanded: true),
      ],
    );
  }
}

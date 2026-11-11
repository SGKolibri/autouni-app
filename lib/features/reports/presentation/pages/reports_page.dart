import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_paths.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/rbac/app_permission.dart';
import '../../../../shared/rbac/rbac_providers.dart';
import '../../../../shared/widgets/cached_async_view.dart';
import '../../domain/report_models.dart';
import '../providers/reports_providers.dart';
import '../widgets/report_widgets.dart';

/// Relatórios do usuário: status de cada um (atualiza sozinho enquanto
/// gera), abrir/compartilhar os prontos e gerar novos.
class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(myReportsProvider);
    final canGenerate = ref.watch(
      hasPermissionProvider(AppPermission.generateReports),
    );

    return Scaffold(
      appBar: const AppTopBar(title: 'Relatórios'),
      floatingActionButton: canGenerate
          ? FloatingActionButton.extended(
              key: const Key('reports-new'),
              onPressed: () => context.push(AppPaths.newReport),
              icon: const Icon(Icons.add),
              label: const Text('Gerar relatório'),
            )
          : null,
      body: CachedAsyncView<List<Report>>(
        value: reports,
        onRetry: () => ref.invalidate(myReportsProvider),
        isEmpty: (list) => list.isEmpty,
        empty: AppEmptyState(
          icon: Icons.description_outlined,
          title: 'Nenhum relatório',
          message: canGenerate
              ? 'Gere relatórios de energia, dispositivos, salas e '
                    'incidentes em PDF, CSV ou XLSX.'
              : 'Seu perfil pode baixar relatórios, mas não gerar novos.',
          actionLabel: canGenerate ? 'Gerar relatório' : null,
          onAction: canGenerate ? () => context.push(AppPaths.newReport) : null,
        ),
        builder: (context, list) => RefreshIndicator(
          onRefresh: () => ref.refresh(myReportsProvider.future),
          child: ListView.separated(
            // Espaço para o FAB não cobrir o último item.
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final report = list[index];
              return ReportTile(
                key: ValueKey('report-${report.id}'),
                report: report,
                onTap: () => context.push(AppPaths.report(report.id)),
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_paths.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/models/campus/campus_models.dart';
import '../../../../shared/rbac/app_permission.dart';
import '../../../../shared/rbac/rbac_providers.dart';
import '../../domain/report_models.dart';
import '../../domain/report_request.dart';
import '../providers/reports_providers.dart';

/// Gerar relatório: tipo, período (nos tipos que usam), local, formato e
/// título.
class NewReportPage extends ConsumerWidget {
  const NewReportPage({this.now, super.key});

  /// Relógio dos atalhos de período (testes).
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(
      hasPermissionProvider(AppPermission.generateReports),
    );
    return Scaffold(
      appBar: const AppTopBar(title: 'Gerar relatório'),
      body: allowed
          ? NewReportForm(now: now ?? DateTime.now)
          : const AppEmptyState(
              icon: Icons.lock_outline,
              title: 'Somente leitura',
              message: 'Seu perfil não permite gerar relatórios.',
            ),
    );
  }
}

class NewReportForm extends ConsumerStatefulWidget {
  const NewReportForm({required this.now, super.key});

  final DateTime Function() now;

  @override
  ConsumerState<NewReportForm> createState() => _NewReportFormState();
}

class _NewReportFormState extends ConsumerState<NewReportForm> {
  final _title = TextEditingController();
  ReportType _type = ReportType.energyConsumption;
  ReportFormat _format = ReportFormat.pdf;
  ReportPeriodPreset _preset = ReportPeriodPreset.thisMonth;
  ReportPeriod? _customPeriod;
  Building? _building;

  /// O usuário mexeu no título: paramos de sugerir.
  bool _titleEdited = false;
  bool _submitting = false;
  Map<String, String> _errors = const {};

  @override
  void initState() {
    super.initState();
    _title.text = _suggestedTitle;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  ReportPeriod? get _period => _preset == ReportPeriodPreset.custom
      ? _customPeriod
      : ReportPeriod.of(_preset, widget.now());

  String get _suggestedTitle => ReportRequest.suggestTitle(
    type: _type,
    period: _period,
    buildingName: _building?.name,
  );

  /// Aplica uma mudança e, se o título ainda é o sugerido, atualiza-o.
  void _update(VoidCallback change) {
    setState(() {
      change();
      _errors = const {};
      if (!_titleEdited) _title.text = _suggestedTitle;
    });
  }

  Future<void> _pickCustomPeriod() async {
    final today = widget.now();
    final current = _period;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 2),
      lastDate: today,
      initialDateRange: current == null
          ? null
          : DateTimeRange(start: current.start, end: current.end),
      helpText: 'Período do relatório',
    );
    if (picked == null) return;
    _update(() {
      _preset = ReportPeriodPreset.custom;
      _customPeriod = ReportPeriod(picked.start, picked.end);
    });
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _submitting = true);
    final outcome = await ref
        .read(reportsControllerProvider)
        .create(
          ReportRequest(
            type: _type,
            format: _format,
            title: _title.text,
            period: _period,
            buildingId: _building?.id,
          ),
        );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _errors = outcome.errors;
    });
    final message = outcome.message;
    if (outcome.isCreated) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Relatório na fila. Você recebe um alerta quando ficar pronto.',
            ),
          ),
        );
      router.canPop() ? router.pop() : router.go(AppPaths.reportsRoot);
    } else if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buildings = ref.watch(reportBuildingsProvider);
    final period = _period;

    Widget section(String title, Widget child, {String? help}) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          if (help != null)
            Text(
              help,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        section(
          'Tipo',
          Column(
            children: [
              for (final type in ReportType.values)
                Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    key: ValueKey('report-type-${type.name}'),
                    selected: type == _type,
                    title: Text(type.label),
                    subtitle: Text(type.description),
                    trailing: type == _type
                        ? const Icon(Icons.check_circle)
                        : const Icon(Icons.circle_outlined),
                    onTap: () => _update(() => _type = type),
                  ),
                ),
            ],
          ),
        ),
        if (_type.usesPeriod)
          section(
            'Período',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final preset in ReportPeriodPreset.values)
                      ChoiceChip(
                        key: ValueKey('report-period-${preset.name}'),
                        label: Text(preset.label),
                        selected: preset == _preset,
                        onSelected: (_) => preset == ReportPeriodPreset.custom
                            ? _pickCustomPeriod()
                            : _update(() => _preset = preset),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  period?.label ?? 'Escolha as datas',
                  key: const Key('report-period-label'),
                  style: theme.textTheme.bodyMedium,
                ),
                if (_errors['period'] case final error?)
                  Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          )
        else
          section(
            'Período',
            const Text('Retrato do momento em que o relatório for gerado.'),
          ),
        section(
          'Local',
          DropdownButtonFormField<String?>(
            key: const Key('report-building'),
            initialValue: _building?.id,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.apartment),
              helperText: buildings.hasError
                  ? 'Não foi possível carregar os prédios.'
                  : null,
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Campus inteiro'),
              ),
              for (final building in buildings.value ?? const <Building>[])
                DropdownMenuItem(
                  value: building.id,
                  child: Text(building.name),
                ),
            ],
            onChanged: (id) => _update(
              () => _building = buildings.value
                  ?.where((b) => b.id == id)
                  .firstOrNull,
            ),
          ),
        ),
        section(
          'Formato',
          SegmentedButton<ReportFormat>(
            key: const Key('report-format'),
            segments: [
              for (final format in ReportFormat.values)
                ButtonSegment(value: format, label: Text(format.label)),
            ],
            selected: {_format},
            onSelectionChanged: (selection) =>
                setState(() => _format = selection.single),
          ),
        ),
        section(
          'Título',
          TextField(
            key: const Key('report-title'),
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {
              _titleEdited = true;
              _errors = const {};
            }),
            decoration: InputDecoration(errorText: _errors['title']),
          ),
        ),
        FilledButton.icon(
          key: const Key('report-submit'),
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.description_outlined),
          label: const Text('Gerar relatório'),
        ),
      ],
    );
  }
}

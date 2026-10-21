import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_paths.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/rbac/app_permission.dart';
import '../../../../shared/rbac/rbac_providers.dart';
import '../../../../shared/widgets/cached_async_view.dart';
import '../../domain/automation_models.dart';
import '../../domain/automation_validators.dart';
import '../../domain/schedule.dart';
import '../providers/automations_providers.dart';
import '../widgets/device_picker_sheet.dart';
import '../widgets/schedule_builder.dart';

/// Criar ([automationId] nulo) ou editar uma automação.
class AutomationFormPage extends ConsumerWidget {
  const AutomationFormPage({this.automationId, super.key});

  final String? automationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = automationId == null ? 'Nova automação' : 'Editar automação';
    final allowed = ref.watch(
      hasPermissionProvider(AppPermission.manageAutomations),
    );
    if (!allowed) {
      return Scaffold(
        appBar: AppTopBar(title: title),
        body: const AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Somente leitura',
          message: 'Seu perfil não permite criar ou editar automações.',
        ),
      );
    }

    final id = automationId;
    if (id == null) {
      return Scaffold(
        appBar: AppTopBar(title: title),
        body: const AutomationForm(),
      );
    }
    final existing = ref.watch(automationProvider(id));
    return Scaffold(
      appBar: AppTopBar(title: title),
      body: CachedAsyncView<Automation>(
        value: existing,
        onRetry: () => ref.invalidate(automationProvider(id)),
        builder: (context, automation) =>
            AutomationForm(key: ValueKey(id), initial: automation),
      ),
    );
  }
}

/// Como a ação é escolhida.
enum ActionMode { device, advanced }

/// O formulário em si; [initial] preenche a edição.
class AutomationForm extends ConsumerStatefulWidget {
  const AutomationForm({this.initial, super.key});

  final Automation? initial;

  @override
  ConsumerState<AutomationForm> createState() => _AutomationFormState();
}

class _AutomationFormState extends ConsumerState<AutomationForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _cron;
  late final TextEditingController _topic;
  late final TextEditingController _payload;

  late TriggerType _trigger;
  late WeeklySchedule _schedule;
  late bool _advancedCron;
  late ActionMode _actionMode;

  /// Alvo do modo dispositivo: tópico de comando, id e nome.
  AutomationAction? _target;
  DeviceAction _command = DeviceAction.off;

  bool _submitted = false;
  bool _saving = false;

  /// Começa em dias úteis às 22:00 — o caso mais comum (desligar à noite).
  static final WeeklySchedule _defaultSchedule = WeeklySchedule(
    days: const {
      Weekday.monday,
      Weekday.tuesday,
      Weekday.wednesday,
      Weekday.thursday,
      Weekday.friday,
    },
    hour: 22,
    minute: 0,
  );

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final action = initial?.action;
    final cron = initial?.cron ?? '';
    final parsed = WeeklySchedule.fromCron(cron);

    _name = TextEditingController(text: initial?.name ?? '');
    _description = TextEditingController(text: initial?.description ?? '');
    _trigger = switch (initial?.triggerType) {
      TriggerType.schedule || null => TriggerType.schedule,
      TriggerType.manual || TriggerType.condition => TriggerType.manual,
    };
    _schedule = parsed ?? _defaultSchedule;
    // Cron que o construtor não representa abre direto no modo avançado.
    _advancedCron = parsed == null && cron.trim().isNotEmpty;
    _cron = TextEditingController(
      text: cron.isEmpty ? _schedule.toCron() : cron,
    );

    if (action != null && !action.isDeviceCommand && initial != null) {
      _actionMode = ActionMode.advanced;
    } else {
      _actionMode = ActionMode.device;
    }
    if (action != null && action.isDeviceCommand) {
      _target = action;
      _command = action.command!;
    }
    _topic = TextEditingController(text: action?.topic ?? '');
    _payload = TextEditingController(
      text: action?.payload == null || action!.payload!.isEmpty
          ? ''
          : const JsonEncoder.withIndent('  ').convert(action.payload),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _cron.dispose();
    _topic.dispose();
    _payload.dispose();
    super.dispose();
  }

  AutomationAction? _buildAction() => switch (_actionMode) {
    ActionMode.device => _target?.copyWith(
      command: _command,
      payload: {'state': _command.state},
    ),
    ActionMode.advanced => AutomationAction(
      topic: _topic.text.trim(),
      payload: parsePayload(_payload.text),
    ),
  };

  String? get _scheduleError {
    if (_trigger != TriggerType.schedule || _advancedCron) return null;
    return _schedule.validationError;
  }

  String? get _targetError =>
      _actionMode == ActionMode.device && _target == null
      ? 'Escolha o dispositivo.'
      : null;

  Future<void> _pickDevice() async {
    final device = await showDevicePicker(context);
    if (device == null || !mounted) return;
    setState(() => _target = AutomationAction.forDevice(device, _command));
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid || _scheduleError != null || _targetError != null) {
      return;
    }
    final action = _buildAction()!;
    final draft = AutomationDraft(
      name: _name.text,
      description: _description.text,
      triggerType: _trigger,
      cron: _advancedCron ? _cron.text.trim() : _schedule.toCron(),
      action: action,
    );

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final outcome = await ref
        .read(automationsControllerProvider)
        .save(draft, id: widget.initial?.id);
    if (!mounted) return;
    setState(() => _saving = false);

    if (!outcome.isSuccess) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(outcome.message ?? 'Não foi possível salvar.'),
          ),
        );
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Automação salva.' : 'Automação criada.'),
        ),
      );
    if (_isEdit) {
      router.pop();
    } else {
      router.pushReplacement(AppPaths.automation(outcome.automation!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wasCondition = widget.initial?.triggerType == TriggerType.condition;

    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );

    return Form(
      key: _formKey,
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          TextFormField(
            key: const Key('automation-name'),
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: validateAutomationName,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const Key('automation-description'),
            controller: _description,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Descrição (opcional)',
            ),
            maxLines: 2,
          ),
          section('Quando', [
            if (wasCondition)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: AppBanner(
                  tone: AppTone.warning,
                  message:
                      'Esta automação usa um gatilho por condição, que não '
                      'pode ser editado no app. Ao salvar, ela passa a ser '
                      'por agenda ou manual.',
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TriggerType>(
                key: const Key('automation-trigger'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: TriggerType.schedule,
                    label: Text('Agenda'),
                    icon: Icon(Icons.schedule),
                  ),
                  ButtonSegment(
                    value: TriggerType.manual,
                    label: Text('Manual'),
                    icon: Icon(Icons.touch_app_outlined),
                  ),
                ],
                selected: {_trigger},
                onSelectionChanged: (value) =>
                    setState(() => _trigger = value.single),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_trigger == TriggerType.manual)
              Text(
                'Roda só quando alguém tocar em "Executar agora".',
                style: theme.textTheme.bodySmall,
              )
            else ...[
              if (_advancedCron)
                TextFormField(
                  key: const Key('automation-cron'),
                  controller: _cron,
                  decoration: const InputDecoration(
                    labelText: 'Expressão cron',
                    helperText: 'minuto hora dia-do-mês mês dia-da-semana',
                  ),
                  style: const TextStyle(fontFamily: 'monospace'),
                  validator: (value) => validateCron(value ?? ''),
                )
              else
                ScheduleBuilder(
                  value: _schedule,
                  showErrors: _submitted,
                  onChanged: (value) => setState(() => _schedule = value),
                ),
              SwitchListTile(
                key: const Key('automation-advanced-cron'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Cron avançado'),
                subtitle: const Text('Para horários que a agenda não cobre'),
                value: _advancedCron,
                onChanged: (value) => setState(() {
                  if (value) {
                    if (_schedule.isValid) _cron.text = _schedule.toCron();
                  } else {
                    final parsed = WeeklySchedule.fromCron(_cron.text);
                    if (parsed != null) _schedule = parsed;
                  }
                  _advancedCron = value;
                }),
              ),
            ],
          ]),
          section('O que fazer', [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ActionMode>(
                key: const Key('automation-action-mode'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ActionMode.device,
                    label: Text('Dispositivo'),
                  ),
                  ButtonSegment(
                    value: ActionMode.advanced,
                    label: Text('MQTT avançado'),
                  ),
                ],
                selected: {_actionMode},
                onSelectionChanged: (value) =>
                    setState(() => _actionMode = value.single),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_actionMode == ActionMode.device) ...[
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<DeviceAction>(
                  key: const Key('automation-command'),
                  showSelectedIcon: false,
                  segments: [
                    for (final action in DeviceAction.values)
                      ButtonSegment(value: action, label: Text(action.label)),
                  ],
                  selected: {_command},
                  onSelectionChanged: (value) =>
                      setState(() => _command = value.single),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                key: const Key('automation-device'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.devices_other),
                title: Text(_target?.deviceName ?? 'Escolher dispositivo'),
                subtitle: _submitted && _targetError != null
                    ? Text(
                        _targetError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      )
                    : _target?.topic == null
                    ? null
                    : Text(_target!.topic!),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDevice,
              ),
            ] else ...[
              TextFormField(
                key: const Key('automation-topic'),
                controller: _topic,
                decoration: const InputDecoration(
                  labelText: 'Tópico MQTT',
                  hintText: 'bloco-a/sala-101/luz/command',
                ),
                validator: validateTopic,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('automation-payload'),
                controller: _payload,
                decoration: const InputDecoration(
                  labelText: 'Payload JSON (opcional)',
                  hintText: '{"state": "OFF"}',
                ),
                style: const TextStyle(fontFamily: 'monospace'),
                maxLines: 4,
                minLines: 2,
                validator: validatePayload,
              ),
            ],
          ]),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            key: const Key('automation-save'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEdit ? 'Salvar alterações' : 'Criar automação'),
          ),
        ],
      ),
    );
  }
}

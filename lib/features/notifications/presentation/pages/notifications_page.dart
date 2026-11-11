import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/models/notification_type.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/cached_async_view.dart';
import '../../../../shared/widgets/notification_style.dart';
import '../../domain/app_notification.dart';
import '../../domain/notification_filter.dart';
import '../notification_opener.dart';
import '../providers/notifications_providers.dart';
import '../widgets/notification_tile.dart';

/// Aba Alertas: central de notificações com filtro por tipo e não lidas,
/// marcar como lida (uma ou todas) e abertura do destino de cada alerta.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key, this.now});

  /// Relógio dos rótulos "Hoje"/"Ontem" (testes).
  final DateTime Function()? now;

  Future<void> _markAll(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await ref.read(notificationsControllerProvider).markAllRead();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error ?? 'Todos os alertas marcados como lidos.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider) ?? 0;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Alertas',
        actions: [
          IconButton(
            key: const Key('notifications-read-all'),
            tooltip: 'Marcar todas como lidas',
            icon: const Icon(Icons.done_all),
            onPressed: unread == 0 ? null : () => _markAll(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(unread: unread),
          Expanded(
            child: CachedAsyncView<List<AppNotification>>(
              value: notifications,
              onRetry: () => ref.invalidate(notificationsProvider),
              isEmpty: (list) => list.isEmpty,
              empty: const AppEmptyState(
                icon: Icons.notifications_none,
                title: 'Nenhum alerta',
                message:
                    'Avisos do campus, de dispositivos e de automações '
                    'aparecem aqui.',
              ),
              builder: (context, _) => RefreshIndicator(
                onRefresh: () => ref.refresh(notificationsProvider.future),
                child: _NotificationsList(now: now ?? DateTime.now),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(notificationFilterProvider);
    final notifier = ref.read(notificationFilterProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          FilterChip(
            key: const Key('filter-unread'),
            label: Text('Não lidas ($unread)'),
            selected: filter.unreadOnly,
            onSelected: notifier.setUnreadOnly,
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            key: const Key('filter-all'),
            label: const Text('Todos'),
            selected: filter.type == null,
            onSelected: (_) => notifier.setType(null),
          ),
          for (final type in NotificationType.values) ...[
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              key: ValueKey('filter-${type.name}'),
              avatar: Icon(
                notificationIcon(type),
                size: 18,
                color: notificationTone(type).resolve(context),
              ),
              label: Text(type.label),
              selected: filter.type == type,
              onSelected: (_) => notifier.setType(type),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationsList extends ConsumerStatefulWidget {
  const _NotificationsList({required this.now});

  final DateTime Function() now;

  @override
  ConsumerState<_NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends ConsumerState<_NotificationsList> {
  /// Notificação cujo link está sendo resolvido.
  String? _opening;

  Future<void> _open(AppNotification notification) async {
    final messenger = ScaffoldMessenger.of(context);
    void show(String message) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    // Marcar como lida não segura a navegação; erro só avisa.
    ref.read(notificationsControllerProvider).markRead(notification).then((
      error,
    ) {
      if (error != null) show(error);
    });

    final link = notification.link;
    if (!notification.hasLink || link == null) {
      await showNotificationDetail(context, notification);
      return;
    }
    setState(() => _opening = notification.id);
    final router = GoRouter.of(context);
    final error = await ref.read(notificationOpenerProvider)(link, router.go);
    if (!mounted) return;
    setState(() => _opening = null);
    if (error != null) show(error);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(visibleNotificationsProvider) ?? const [];
    final filter = ref.watch(notificationFilterProvider);
    final visible = filter.apply(all);

    if (visible.isEmpty) {
      return AppEmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: filter.unreadOnly && filter.type == null
            ? 'Tudo lido por aqui'
            : 'Nenhum alerta com esse filtro',
        actionLabel: 'Limpar filtros',
        onAction: () {
          final notifier = ref.read(notificationFilterProvider.notifier);
          notifier
            ..setType(null)
            ..setUnreadOnly(false);
        },
      );
    }

    final theme = Theme.of(context);
    final days = groupByDay(visible, now: widget.now());
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        for (final day in days) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text(
              day.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final notification in day.items)
            NotificationTile(
              key: ValueKey('notification-${notification.id}'),
              notification: notification,
              opening: _opening == notification.id,
              onTap: () => _open(notification),
            ),
        ],
      ],
    );
  }
}

/// Alerta sem tela de destino: mostra o texto completo.
Future<void> showNotificationDetail(
  BuildContext context,
  AppNotification notification,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) {
    final theme = Theme.of(context);
    final createdAt = notification.createdAt;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBadge(
              notification.type.label,
              tone: notificationTone(notification.type),
              icon: notificationIcon(notification.type),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(notification.title, style: theme.textTheme.titleMedium),
            if (notification.message.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(notification.message, style: theme.textTheme.bodyMedium),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                formatDateTime(createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  },
);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached.dart';
import '../design_system/design_system.dart';
import '../utils/error_messages.dart';
import '../utils/formatters.dart';

/// Renderiza os estados transversais de um valor carregado com cache:
///
/// - carregando sem nada guardado → [loading] (skeleton);
/// - erro sem nada guardado → [AppErrorState] com "Tentar de novo";
/// - dados vazios → [empty];
/// - dados do cache enquanto a rede responde → barra de progresso fina;
/// - dados do cache porque a rede falhou → banner de "dados salvos".
class CachedAsyncView<T> extends StatelessWidget {
  const CachedAsyncView({
    required this.value,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.empty,
    this.loading = const AppListSkeleton(),
    super.key,
  });

  final AsyncValue<Cached<T>> value;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Widget loading;

  @override
  Widget build(BuildContext context) {
    final cached = value.value;
    if (cached == null) {
      if (value.hasError) {
        return AppErrorState(
          message: describeError(value.error),
          onRetry: onRetry,
        );
      }
      return loading;
    }

    final showEmpty = (isEmpty?.call(cached.data) ?? false) && empty != null;
    return Column(
      children: [
        if (cached.offline)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: StaleDataBanner(savedAt: cached.savedAt!, onRetry: onRetry),
          )
        else if (cached.isStale || value.isRefreshing)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(child: showEmpty ? empty! : builder(context, cached.data)),
      ],
    );
  }
}

/// "Sem conexão — mostrando dados salvos às 09:05."
class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({required this.savedAt, this.onRetry, super.key});

  final DateTime savedAt;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppBanner(
      tone: AppTone.neutral,
      icon: Icons.cloud_off,
      message:
          'Sem conexão. Mostrando dados salvos às ${formatClock(savedAt)}.',
      action: onRetry == null
          ? null
          : AppBannerAction(label: 'Tentar de novo', onPressed: onRetry!),
    );
  }
}

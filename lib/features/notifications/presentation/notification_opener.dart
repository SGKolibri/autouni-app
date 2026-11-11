import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/notification_link_resolver.dart';

/// Mensagem quando o destino ainda não abre no app.
const String unsupportedLinkMessage =
    'Este alerta ainda não abre uma tela no app.';

/// Abre o `link` de uma notificação: traduz para um caminho do app e chama
/// [go]. Devolve a mensagem para o usuário quando não dá para abrir, ou
/// `null` em sucesso. Usado pela central e pelo toque no push.
Future<String?> openNotificationLink(
  Ref ref,
  String link,
  void Function(String location) go,
) async {
  try {
    final location = await ref
        .read(notificationLinkResolverProvider)
        .resolve(link);
    if (location == null) return unsupportedLinkMessage;
    go(location);
    return null;
  } on ApiException catch (error) {
    return 'Não foi possível abrir: ${error.message}';
  }
}

/// Atalho para [openNotificationLink] a partir de widgets.
final notificationOpenerProvider =
    Provider<Future<String?> Function(String link, void Function(String) go)>(
      (ref) =>
          (link, go) => openNotificationLink(ref, link, go),
      name: 'notificationOpenerProvider',
    );

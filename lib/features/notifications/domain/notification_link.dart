import 'package:flutter/foundation.dart';

import '../../../core/router/app_paths.dart';
import '../../../core/router/app_tab.dart';

/// Entidades cujo caminho no app depende da hierarquia (prédio → andar →
/// sala) e precisa de uma consulta à API.
enum LinkEntity { device, room, floor }

/// Para onde um `link` de notificação leva.
@immutable
sealed class LinkTarget {
  const LinkTarget();
}

/// Já é um caminho do app.
class LinkLocation extends LinkTarget {
  const LinkLocation(this.location);

  final String location;

  @override
  bool operator ==(Object other) =>
      other is LinkLocation && other.location == location;

  @override
  int get hashCode => location.hashCode;
}

/// Precisa consultar a API para montar o caminho.
class LinkLookup extends LinkTarget {
  const LinkLookup(this.entity, this.id);

  final LinkEntity entity;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is LinkLookup && other.entity == entity && other.id == id;

  @override
  int get hashCode => Object.hash(entity, id);
}

/// Ainda não abre no app ou não é um caminho interno.
class LinkUnsupported extends LinkTarget {
  const LinkUnsupported();
}

/// Lê o `link` gravado pelo backend (`/devices/<id>`, `/rooms/<id>`...).
/// Só aceita caminhos internos; caminhos do próprio app passam direto.
LinkTarget classifyLink(String link) {
  final trimmed = link.trim();
  if (!trimmed.startsWith('/') || trimmed.startsWith('//')) {
    return const LinkUnsupported();
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.hasScheme || uri.hasAuthority) {
    return const LinkUnsupported();
  }

  final appRoots = [
    for (final tab in AppTab.values) tab.path,
    AppPaths.energyRoot,
    AppPaths.reportsRoot,
  ];
  if (appRoots.any(
    (root) => uri.path == root || uri.path.startsWith('$root/'),
  )) {
    return LinkLocation(trimmed);
  }

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length != 2) return const LinkUnsupported();
  final [kind, id] = segments;
  return switch (kind) {
    'devices' => LinkLookup(LinkEntity.device, id),
    'rooms' => LinkLookup(LinkEntity.room, id),
    'floors' => LinkLookup(LinkEntity.floor, id),
    'buildings' => LinkLocation(AppPaths.building(id)),
    _ => const LinkUnsupported(),
  };
}

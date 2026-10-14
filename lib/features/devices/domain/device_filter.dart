import 'package:flutter/foundation.dart';

import '../../../shared/models/campus/campus_enums.dart';
import '../../../shared/models/campus/campus_models.dart';

/// Disponibilidade no filtro da lista global.
enum AvailabilityFilter {
  all('Todos'),
  online('Online'),
  offline('Offline');

  const AvailabilityFilter(this.label);

  final String label;
}

/// Busca e filtros da lista global de dispositivos.
@immutable
class DeviceFilter {
  const DeviceFilter({
    this.query = '',
    this.statuses = const {},
    this.types = const {},
    this.availability = AvailabilityFilter.all,
  });

  final String query;

  /// Vazio = todos os status.
  final Set<DeviceStatus> statuses;

  /// Vazio = todos os tipos.
  final Set<DeviceType> types;
  final AvailabilityFilter availability;

  /// Filtros do bottom sheet em uso (a busca não conta).
  int get activeCount =>
      statuses.length +
      types.length +
      (availability == AvailabilityFilter.all ? 0 : 1);

  bool get isEmpty => query.trim().isEmpty && activeCount == 0;

  DeviceFilter copyWith({
    String? query,
    Set<DeviceStatus>? statuses,
    Set<DeviceType>? types,
    AvailabilityFilter? availability,
  }) => DeviceFilter(
    query: query ?? this.query,
    statuses: statuses ?? this.statuses,
    types: types ?? this.types,
    availability: availability ?? this.availability,
  );

  @override
  bool operator ==(Object other) =>
      other is DeviceFilter &&
      other.query == query &&
      setEquals(other.statuses, statuses) &&
      setEquals(other.types, types) &&
      other.availability == availability;

  @override
  int get hashCode => Object.hash(
    query,
    Object.hashAllUnordered(statuses),
    Object.hashAllUnordered(types),
    availability,
  );
}

/// Aplica [filter] e ordena por nome. A busca ignora maiúsculas e acentos e
/// procura no nome, no tipo e na localização ("sala 101", "bloco a").
List<Device> filterDevices(Iterable<Device> devices, DeviceFilter filter) {
  final terms = normalizeSearch(filter.query)
      .split(' ')
      .where((term) => term.isNotEmpty)
      .toList();

  final result = devices.where((device) {
    if (filter.statuses.isNotEmpty &&
        !filter.statuses.contains(device.status)) {
      return false;
    }
    if (filter.types.isNotEmpty && !filter.types.contains(device.type)) {
      return false;
    }
    switch (filter.availability) {
      case AvailabilityFilter.online when !device.online:
      case AvailabilityFilter.offline when device.online:
        return false;
      default:
        break;
    }
    if (terms.isEmpty) return true;
    final haystack = normalizeSearch(
      '${device.name} ${device.type.label} ${device.locationLabel ?? ''}',
    );
    return terms.every(haystack.contains);
  }).toList();

  result.sort(
    (a, b) => normalizeSearch(a.name).compareTo(normalizeSearch(b.name)),
  );
  return result;
}

const Map<String, String> _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
  'ç': 'c', 'ñ': 'n',
};

/// Minúsculas, sem acentos e com espaços simples.
String normalizeSearch(String text) {
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Uma "página" da lista: os itens visíveis até [limit] e se há mais.
class DevicePage {
  const DevicePage({required this.items, required this.total});

  factory DevicePage.of(List<Device> filtered, int limit) =>
      DevicePage(items: filtered.take(limit).toList(), total: filtered.length);

  final List<Device> items;

  /// Total depois dos filtros.
  final int total;

  bool get hasMore => items.length < total;
}

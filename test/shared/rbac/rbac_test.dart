import 'package:autouni_app/shared/models/user_role.dart';
import 'package:autouni_app/shared/rbac/app_permission.dart';
import 'package:autouni_app/shared/rbac/permission_gate.dart';
import 'package:autouni_app/shared/rbac/rbac_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole.can', () {
    test('VIEWER é somente leitura: nenhuma permissão', () {
      for (final permission in AppPermission.values) {
        expect(UserRole.viewer.can(permission), isFalse, reason: '$permission');
      }
    });

    for (final role in [
      UserRole.admin,
      UserRole.coordinator,
      UserRole.technician,
    ]) {
      test('${role.apiValue} pode controlar dispositivos', () {
        expect(role.can(AppPermission.controlDevices), isTrue);
        expect(role.can(AppPermission.bulkControlDevices), isTrue);
      });
    }
  });

  group('hasPermissionProvider', () {
    test('sem sessão (papel nulo) nega tudo', () {
      final container = ProviderContainer.test();

      expect(
        container.read(hasPermissionProvider(AppPermission.controlDevices)),
        isFalse,
      );
    });

    test('segue o papel da sessão', () {
      final container = ProviderContainer.test(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.technician),
        ],
      );

      expect(
        container.read(hasPermissionProvider(AppPermission.controlDevices)),
        isTrue,
      );
    });
  });

  group('PermissionGate', () {
    Future<void> pumpGate(WidgetTester tester, UserRole? role) =>
        tester.pumpWidget(
          ProviderScope(
            overrides: [currentUserRoleProvider.overrideWithValue(role)],
            child: const MaterialApp(
              home: PermissionGate(
                permission: AppPermission.controlDevices,
                fallback: Text('somente leitura'),
                child: Text('controlar'),
              ),
            ),
          ),
        );

    testWidgets('não renderiza a ação para VIEWER', (tester) async {
      await pumpGate(tester, UserRole.viewer);

      expect(find.text('controlar'), findsNothing);
      expect(find.text('somente leitura'), findsOneWidget);
    });

    testWidgets('renderiza a ação para quem tem permissão', (tester) async {
      await pumpGate(tester, UserRole.admin);

      expect(find.text('controlar'), findsOneWidget);
    });
  });
}

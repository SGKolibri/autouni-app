import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/features/automations/data/automations_repository.dart';
import 'package:autouni_app/features/automations/domain/automation_models.dart';
import 'package:autouni_app/features/automations/presentation/automations_routes.dart';
import 'package:autouni_app/features/automations/presentation/pages/automation_detail_page.dart';
import 'package:autouni_app/features/automations/presentation/pages/automation_form_page.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:autouni_app/shared/rbac/rbac_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/automation_fixtures.dart';
import '../../../support/pump_router_app.dart';

class _MockRepository extends Mock implements AutomationsRepository {}

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    final automation = Automation.fromJson(automationJson(id: 'a1'));
    when(() => repository.watchOne('a1'))
        .thenAnswer((_) => Stream.value(Cached(automation)));
    when(() => repository.watchHistory('a1'))
        .thenAnswer((_) => Stream.value(const Cached(<AutomationRun>[])));
  });

  Future<void> pumpAt(WidgetTester tester, String location) async {
    await tester.pumpRouterApp(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/automations',
          builder: (_, _) => const SizedBox(),
          routes: automationsRoutes(),
        ),
      ],
      overrides: [
        automationsRepositoryProvider.overrideWithValue(repository),
        currentUserRoleProvider.overrideWithValue(UserRole.admin),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('"new" abre a criação, não um detalhe com id "new"', (
    tester,
  ) async {
    await pumpAt(tester, AppPaths.newAutomation);

    expect(
      tester
          .widget<AutomationFormPage>(find.byType(AutomationFormPage))
          .automationId,
      isNull,
    );
    expect(find.byType(AutomationDetailPage), findsNothing);
  });

  testWidgets('id abre o detalhe', (tester) async {
    await pumpAt(tester, AppPaths.automation('a1'));

    expect(
      tester
          .widget<AutomationDetailPage>(find.byType(AutomationDetailPage))
          .automationId,
      'a1',
    );
  });

  testWidgets('/edit abre a edição com o id', (tester) async {
    await pumpAt(tester, AppPaths.editAutomation('a1'));

    expect(
      tester
          .widget<AutomationFormPage>(find.byType(AutomationFormPage))
          .automationId,
      'a1',
    );
  });
}

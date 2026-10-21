#!/usr/bin/env bash
# Roda localmente os mesmos gates da CI (.github/workflows/main.yml):
# formatação, análise estática, testes com cobertura e limiar de cobertura.
#
#   ./tool/check.sh            # limiar padrão (80%)
#   MIN_COVERAGE=85 ./tool/check.sh
set -euo pipefail

cd "$(dirname "$0")/.."
MIN_COVERAGE="${MIN_COVERAGE:-80}"

trap 'dart run tool/coverage.dart clean' EXIT

echo "==> Formatação"
dart format --output=none --set-exit-if-changed \
  $(find lib test tool -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart')

echo "==> Análise estática"
flutter analyze

echo "==> Testes com cobertura"
dart run tool/coverage.dart prepare
flutter test --coverage
dart run tool/coverage.dart clean

echo "==> Limiar de cobertura (${MIN_COVERAGE}%)"
dart run tool/coverage.dart check --min="${MIN_COVERAGE}"

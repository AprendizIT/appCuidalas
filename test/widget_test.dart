// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidalas_app/main.dart';

void main() {
  testWidgets('App se construye y muestra título', (WidgetTester tester) async {
    // Construir la app y esperar a que se estabilice
    await tester.pumpWidget(const CuidalasApp());
    await tester.pumpAndSettle();

    // Verificar que existe un MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verificar que el título principal está presente
    expect(find.text('Cuídalas'), findsOneWidget);
  });
}

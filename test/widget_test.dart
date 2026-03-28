import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:m_finagent_mobile/app.dart';

void main() {
  testWidgets('Renders app tabs', (tester) async {
    await tester.pumpWidget(const FinAgentApp());
    await tester.pumpAndSettle();

    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Navigates to profile tab', (tester) async {
    await tester.pumpWidget(const FinAgentApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Savings Goal'), findsOneWidget);
  });
}

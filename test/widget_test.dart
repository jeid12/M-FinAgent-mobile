import 'package:flutter_test/flutter_test.dart';

import 'package:m_finagent_mobile/app.dart';
import 'package:m_finagent_mobile/state/app_state.dart';

void main() {
  testWidgets('Shows auth actions before login', (tester) async {
    final state = AppState();

    await tester.pumpWidget(FinAgentApp(appState: state, autoInitialize: false));
    await tester.pumpAndSettle();

    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Navigates to profile tab when authenticated', (tester) async {
    final state = AppState();
    state.isAuthenticated = true;
    state.loading = false;
    state.activePhoneNumber = '+250788000001';

    await tester.pumpWidget(FinAgentApp(appState: state, autoInitialize: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Your Financial Profile'), findsOneWidget);
  });
}

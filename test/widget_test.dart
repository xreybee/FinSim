import 'package:flutter_test/flutter_test.dart';
import 'package:finsim/main.dart';

void main() {
  testWidgets('App renders successfully and displays main text', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Since mock session is auto-enabled when Firebase configurations are missing,
    // the app will render the NavigationShell directly in tests. We check for both.
    final hasDashboard = find.text('Ringkasan').evaluate().isNotEmpty;
    final hasLogin = find.text('Masuk ke Akun Anda').evaluate().isNotEmpty;

    expect(hasDashboard || hasLogin, isTrue);
  });
}

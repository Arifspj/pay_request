import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pay_request/services/theme_provider.dart';
import 'package:pay_request/screens/main_shell.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const PaymentRequestApp(),
      ),
    );

    expect(find.text('Pay Request'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}

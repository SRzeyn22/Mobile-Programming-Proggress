import 'package:flutter_application_1/UAS/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('CountryExplorerUasApp menampilkan halaman utama', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CountryExplorerUasApp());
    await tester.pump();

    expect(find.text('COUNTRY EXPLORER'), findsOneWidget);
    expect(find.text('Jelajahi Negara'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/meya_database.dart';
import 'package:meya/main.dart';
import 'package:meya/theme/meya_logo.dart';

void main() {
  testWidgets('MEYA app loads', (WidgetTester tester) async {
    await tester.pumpWidget(MeyaApp(database: MeyaDatabase()));

    // The logo shows while MEYA checks for an account to reopen.
    expect(find.byType(MeyaLogo), findsOneWidget);
  });
}

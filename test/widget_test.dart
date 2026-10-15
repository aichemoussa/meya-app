import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/meya_database.dart';
import 'package:meya/main.dart';

void main() {
  testWidgets('MEYA app loads', (WidgetTester tester) async {
    await tester.pumpWidget(MeyaApp(database: MeyaDatabase()));

    expect(find.text('MEYA'), findsOneWidget);
  });
}

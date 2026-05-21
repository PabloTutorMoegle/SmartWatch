import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartcatch_app/ble/watch_service.dart';
import 'package:smartcatch_app/main.dart';

void main() {
  testWidgets('App shows scanner on launch', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WatchService(),
        child: const SmartCatchApp(),
      ),
    );
    expect(find.text('SmartCatch'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ninja_trip_log/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Boise trip is default and picker lists Ride Home', (tester) async {
    await tester.pumpWidget(const NinjaTripLogApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('BOISE → HOME'), findsWidgets);
    expect(find.text('TRIP'), findsOneWidget);
    expect(find.text('COMPANION'), findsOneWidget);

    await tester.tap(find.text('TRIP'));
    await tester.pumpAndSettle();

    expect(find.text('Ride Home'), findsOneWidget);
    expect(find.text('Boise → Home'), findsWidgets);
  });
}

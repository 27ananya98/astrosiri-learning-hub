import 'package:flutter_test/flutter_test.dart';
import 'package:astro_siri_learning_hub/main.dart';
import 'package:astro_siri_learning_hub/core/constants/app_strings.dart';

void main() {
  testWidgets('App renders splash screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(const AstroSiriApp());
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.appTagline), findsOneWidget);
  });
}

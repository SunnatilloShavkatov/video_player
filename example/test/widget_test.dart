import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_example/main.dart';

void main() {
  testWidgets('Renders Video Player example main page', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Video Player Plugin'), findsOneWidget);
    expect(find.text('Play Fullscreen Video'), findsOneWidget);
    expect(find.text('Open Embedded View Demo'), findsOneWidget);
    expect(find.byType(FilledButton), findsNWidgets(2));
  });
}

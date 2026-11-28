import 'package:flutter_test/flutter_test.dart';
import 'package:native_platform_ui/native_platform_ui.dart';
import 'package:native_playground/main.dart';

void main() {
  testWidgets(
    'linked counter disables subtraction at zero and updates both ways',
    (tester) async {
      await tester.pumpWidget(const PlaygroundApp());
      IosButton group() => tester
          .widgetList<IosButton>(find.byType(IosButton))
          .firstWhere((button) => button.linkedButtons != null);
      expect(group().linkedButtons!.first.enabled, isFalse);
      group().linkedButtons!.last.onPressed!();
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(group().linkedButtons!.first.enabled, isTrue);
      group().linkedButtons!.first.onPressed!();
      await tester.pump();
      expect(find.text('0'), findsOneWidget);
      expect(group().linkedButtons!.first.enabled, isFalse);
    },
  );
}

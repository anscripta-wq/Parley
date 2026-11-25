import 'package:flutter_test/flutter_test.dart';
import 'package:parley/main.dart';

void main() {
  testWidgets('ParleyApp smoke test', (WidgetTester tester) async {
    expect(ParleyApp, isNotNull);
  });
}
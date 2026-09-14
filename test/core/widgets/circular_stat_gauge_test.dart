import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/widgets/circular_stat_gauge.dart';

void main() {
  testWidgets('renders the percentage label for the given value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CircularStatGauge(value: 0.65, color: Colors.green, label: 'Teknikler'),
        ),
      ),
    );

    expect(find.text('%65'), findsOneWidget);
    expect(find.text('Teknikler'), findsOneWidget);
  });

  testWidgets('clamps out-of-range values into the label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CircularStatGauge(value: 1.4, color: Colors.green, label: 'Test'),
        ),
      ),
    );

    expect(find.text('%100'), findsOneWidget);
  });
}

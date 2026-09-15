import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/theme/app_colors.dart';
import 'package:gym_app/core/widgets/status_pill.dart';

void main() {
  testWidgets('positive pill uses successSurface background and primary text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: StatusPill(text: 'Aktif', isPositive: true))));

    final container = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppColors.successSurface);

    final text = tester.widget<Text>(find.text('Aktif'));
    expect(text.style?.color, AppColors.primary);
    expect(text.style?.fontWeight, FontWeight.w600);
  });

  testWidgets('non-positive pill uses surfaceElevated background and faint text, still bold', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: StatusPill(text: 'Donduruldu', isPositive: false))));

    final container = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppColors.surfaceElevated);

    final text = tester.widget<Text>(find.text('Donduruldu'));
    expect(text.style?.color, AppColors.onBackgroundFaint);
    expect(text.style?.fontWeight, FontWeight.w600);
  });
}

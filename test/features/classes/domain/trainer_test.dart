import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/classes/domain/trainer.dart';

void main() {
  test('fromJson parses all fields including a null branchId', () {
    final trainer = Trainer.fromJson({'id': 99, 'fullName': 'Ali Antrenör', 'branchId': null});

    expect(trainer.id, 99);
    expect(trainer.fullName, 'Ali Antrenör');
    expect(trainer.branchId, isNull);
  });
}

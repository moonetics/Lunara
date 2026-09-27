import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/core/constants/medical_constants.dart';

void main() {
  test('Medical constants verification test', () {
    expect(MedicalConstants.normalMinCycleLength, 21);
    expect(MedicalConstants.normalMaxCycleLength, 35);
    expect(MedicalConstants.baselineDefaultCycleLength, 28);
    expect(MedicalConstants.outlierGapThreshold, 45);
    expect(MedicalConstants.earlyDelayThreshold, 3);
    expect(MedicalConstants.pogiCitation.contains('POGI'), isTrue);
    expect(MedicalConstants.niceGuidelinesCitation.contains('NICE'), isTrue);
  });
}

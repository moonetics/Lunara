import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/core/database/models/app_config_model.dart';
import 'package:lunara/core/widgets/medical_term_bottom_sheet.dart';

void main() {
  group('Medical Terms Registry & Plain Language Tests', () {
    test('1. Semua istilah medis esensial terdaftar lengkap dengan rujukan awam', () {
      final expectedKeys = [
        'hpo_axis',
        'dysmenorrhea',
        'menorrhagia',
        'secondary_amenorrhea',
        'fha',
        'follicular_phase',
        'ovulation_phase',
        'luteal_phase',
        'fabm',
        'ttc_wilcox',
      ];

      for (final key in expectedKeys) {
        final term = MedicalTermRegistry.terms[key];
        expect(term, isNotNull, reason: 'Istilah $key harus terdaftar');
        expect(term!.commonTitle.isNotEmpty, isTrue);
        expect(term.medicalTerm.isNotEmpty, isTrue);
        expect(term.plainExplanation.isNotEmpty, isTrue);
        expect(term.biologicalMechanism.isNotEmpty, isTrue);
        expect(term.practicalTips.length, greaterThanOrEqualTo(2));
        expect(term.whenToSeeDoctor.isNotEmpty, isTrue);
      }
    });

    test('2. AppConfigModel mendukung 3 tujuan pelacakan siklus & keluarga berencana', () {
      final defaultConfig = AppConfigModel();
      expect(defaultConfig.appGoal, 'health_tracking');
      expect(defaultConfig.isHealthTracking, isTrue);
      expect(defaultConfig.isNaturalContraception, isFalse);
      expect(defaultConfig.isPregnancyProgram, isFalse);

      final fabmConfig = AppConfigModel(appGoal: 'natural_contraception');
      expect(fabmConfig.appGoal, 'natural_contraception');
      expect(fabmConfig.isNaturalContraception, isTrue);
      expect(fabmConfig.isPregnancyProgram, isFalse);

      final promilConfig = AppConfigModel(appGoal: 'pregnancy_program');
      expect(promilConfig.appGoal, 'pregnancy_program');
      expect(promilConfig.isPregnancyProgram, isTrue);
      expect(promilConfig.isNaturalContraception, isFalse);
      expect(promilConfig.isHealthTracking, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/core/services/triage_engine.dart';

void main() {
  group('TriageEngine - Clinical Decision Tree Evaluation', () {
    test('1. Red Flag: Nyeri panggul hebat mendadak memicu status darurat dokter Sp.OG', () {
      const input = TriageInput(
        daysDelayed: 4,
        severePelvicPain: true,
      );

      final result = TriageEngine.evaluate(input);

      expect(result.isRedFlag, isTrue);
      expect(result.redFlagWarning, isNotNull);
      expect(result.redFlagWarning, contains('kehamilan ektopik'));
    });

    test('2. Red Flag: Keterlambatan >= 90 hari memicu status amenore sekunder', () {
      const input = TriageInput(
        daysDelayed: 92,
        severePelvicPain: false,
      );

      final result = TriageEngine.evaluate(input);

      expect(result.isRedFlag, isTrue);
      expect(result.redFlagWarning, contains('amenore sekunder'));
    });

    test('3. Stres Tinggi: Memetakan penekanan hormon GnRH & poros HPA (Speroff Bab 11)', () {
      const input = TriageInput(
        daysDelayed: 5,
        stressLevel: 5, // Sangat tinggi
      );

      final result = TriageEngine.evaluate(input);

      expect(result.isRedFlag, isFalse);
      expect(
        result.factors.any((f) => f.title.contains('Stres') && f.citation.contains('Speroff')),
        isTrue,
      );
      expect(result.partnerGuidance, contains('stres'));
    });

    test('4. Risiko Kehamilan Belum Tes: Menganjurkan tes pack urine pagi hari (ACOG)', () {
      const input = TriageInput(
        daysDelayed: 4,
        hasPregnancyRisk: true,
        pregnancyTestTaken: false,
      );

      final result = TriageEngine.evaluate(input);

      expect(
        result.factors.any((f) => f.title.contains('Kehamilan') && f.citation.contains('ACOG')),
        isTrue,
      );
      expect(result.generalLifestyleAdvice.any((a) => a.contains('tes kehamilan')), isTrue);
    });

    test('5. Kehamilan Positif: Rekomendasi antenatal care dokter Sp.OG', () {
      const input = TriageInput(
        daysDelayed: 7,
        hasPregnancyRisk: true,
        pregnancyTestTaken: true,
        pregnancyTestResult: 'positive',
      );

      final result = TriageEngine.evaluate(input);

      expect(
        result.factors.any((f) => f.title.contains('Kehamilan Awal (hCG Positif)')),
        isTrue,
      );
    });

    test('6. Diet Ekstrem: Memetakan Functional Hypothalamic Amenorrhea & Leptin (ACOG 219)', () {
      const input = TriageInput(
        daysDelayed: 6,
        drasticDietOrWeightChange: true,
      );

      final result = TriageEngine.evaluate(input);

      expect(
        result.factors.any((f) => f.title.contains('Functional Hypothalamic Amenorrhea')),
        isTrue,
      );
    });

    test('7. Variasi Fisiologis Normal: Telat ringan tanpa faktor risiko patologis (Guyton & Hall)', () {
      const input = TriageInput(
        daysDelayed: 2,
        stressLevel: 2,
        drasticDietOrWeightChange: false,
        hasPregnancyRisk: false,
      );

      final result = TriageEngine.evaluate(input);

      expect(result.isRedFlag, isFalse);
      expect(
        result.factors.any((f) => f.title.contains('Variasi Fisiologis Siklus Normal')),
        isTrue,
      );
    });
  });
}

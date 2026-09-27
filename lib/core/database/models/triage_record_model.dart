import 'package:hive/hive.dart';

/// Model Rekam Evaluasi Triage Keterlambatan Siklus (Hive TypeId: 3)
class TriageRecordModel extends HiveObject {
  String triageId;
  DateTime testDate;
  int daysDelayed;
  bool hasPregnancyRisk;
  bool pregnancyTestTaken;
  String pregnancyTestResult; // 'negative', 'positive', 'not_tested'
  int stressLevel; // 1 (Rendah) s/d 5 (Sangat Tinggi)
  bool drasticDietOrWeightChange;
  bool intenseExercise;
  bool emergencyContraceptive;
  bool severePelvicPain;
  List<String> probableFactors;
  String recommendationSummary;
  String primaryCitation;
  bool isRedFlag;

  TriageRecordModel({
    required this.triageId,
    required this.testDate,
    required this.daysDelayed,
    this.hasPregnancyRisk = false,
    this.pregnancyTestTaken = false,
    this.pregnancyTestResult = 'not_tested',
    this.stressLevel = 1,
    this.drasticDietOrWeightChange = false,
    this.intenseExercise = false,
    this.emergencyContraceptive = false,
    this.severePelvicPain = false,
    this.probableFactors = const [],
    this.recommendationSummary = '',
    this.primaryCitation = '',
    this.isRedFlag = false,
  });
}

/// TypeAdapter Manual untuk TriageRecordModel (TypeId: 3)
class TriageRecordModelAdapter extends TypeAdapter<TriageRecordModel> {
  @override
  final int typeId = 3;

  @override
  TriageRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TriageRecordModel(
      triageId: fields[0] as String,
      testDate: DateTime.fromMillisecondsSinceEpoch(fields[1] as int),
      daysDelayed: fields[2] as int? ?? 0,
      hasPregnancyRisk: fields[3] as bool? ?? false,
      pregnancyTestTaken: fields[4] as bool? ?? false,
      pregnancyTestResult: fields[5] as String? ?? 'not_tested',
      stressLevel: fields[6] as int? ?? 1,
      drasticDietOrWeightChange: fields[7] as bool? ?? false,
      intenseExercise: fields[8] as bool? ?? false,
      emergencyContraceptive: fields[9] as bool? ?? false,
      severePelvicPain: fields[10] as bool? ?? false,
      probableFactors: (fields[11] as List?)?.cast<String>() ?? const [],
      recommendationSummary: fields[12] as String? ?? '',
      primaryCitation: fields[13] as String? ?? '',
      isRedFlag: fields[14] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, TriageRecordModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.triageId)
      ..writeByte(1)
      ..write(obj.testDate.millisecondsSinceEpoch)
      ..writeByte(2)
      ..write(obj.daysDelayed)
      ..writeByte(3)
      ..write(obj.hasPregnancyRisk)
      ..writeByte(4)
      ..write(obj.pregnancyTestTaken)
      ..writeByte(5)
      ..write(obj.pregnancyTestResult)
      ..writeByte(6)
      ..write(obj.stressLevel)
      ..writeByte(7)
      ..write(obj.drasticDietOrWeightChange)
      ..writeByte(8)
      ..write(obj.intenseExercise)
      ..writeByte(9)
      ..write(obj.emergencyContraceptive)
      ..writeByte(10)
      ..write(obj.severePelvicPain)
      ..writeByte(11)
      ..write(obj.probableFactors)
      ..writeByte(12)
      ..write(obj.recommendationSummary)
      ..writeByte(13)
      ..write(obj.primaryCitation)
      ..writeByte(14)
      ..write(obj.isRedFlag);
  }
}

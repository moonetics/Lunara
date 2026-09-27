import 'package:hive/hive.dart';

/// Model Catatan Harian (Quick-Log) Lunara (Hive TypeId: 2)
class DailyEntryModel extends HiveObject {
  String entryId;
  String cycleId;
  DateTime entryDate;
  String flowIntensity; // 'none', 'spotting', 'light', 'medium', 'heavy'
  String mood;          // 'happy', 'calm', 'tired', 'anxious', 'irritable'
  List<String> symptoms; // ['cramps', 'headache', 'bloating', 'backache', dll]
  String? notes;
  bool hasIntimacy;      // true jika ada aktivitas seksual/intim
  bool? usedProtection;  // true = pakai pengaman, false = tanpa pengaman, null = tidak spesifik

  DailyEntryModel({
    required this.entryId,
    required this.cycleId,
    required this.entryDate,
    this.flowIntensity = 'none',
    this.mood = 'calm',
    this.symptoms = const [],
    this.notes,
    this.hasIntimacy = false,
    this.usedProtection,
  });

  bool get hasPeriodFlow => flowIntensity != 'none';
}

/// TypeAdapter Manual untuk DailyEntryModel (TypeId: 2)
class DailyEntryModelAdapter extends TypeAdapter<DailyEntryModel> {
  @override
  final int typeId = 2;

  @override
  DailyEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyEntryModel(
      entryId: fields[0] as String,
      cycleId: fields[1] as String,
      entryDate: DateTime.fromMillisecondsSinceEpoch(fields[2] as int),
      flowIntensity: fields[3] as String? ?? 'none',
      mood: fields[4] as String? ?? 'calm',
      symptoms: (fields[5] as List?)?.cast<String>() ?? const [],
      notes: fields[6] as String?,
      hasIntimacy: fields[7] as bool? ?? false,
      usedProtection: fields[8] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyEntryModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.entryId)
      ..writeByte(1)
      ..write(obj.cycleId)
      ..writeByte(2)
      ..write(obj.entryDate.millisecondsSinceEpoch)
      ..writeByte(3)
      ..write(obj.flowIntensity)
      ..writeByte(4)
      ..write(obj.mood)
      ..writeByte(5)
      ..write(obj.symptoms)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.hasIntimacy)
      ..writeByte(8)
      ..write(obj.usedProtection);
  }
}

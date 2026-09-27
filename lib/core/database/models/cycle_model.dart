import 'package:hive/hive.dart';

/// Model Siklus Menstruasi Lunara (Hive TypeId: 1)
class CycleModel extends HiveObject {
  String cycleId;
  DateTime startDate;
  DateTime? endDate;
  int cycleLengthDays;
  int periodDurationDays;
  bool isOutlier; // Ditandai jika jeda > 45 hari (data bolong)
  bool isOngoing; // Siklus yang sedang berlangsung saat ini
  bool isUnrecordedGap; // Menandakan jeda bolong/lupa catat (bukan amenore patologis)
  String? notes;

  CycleModel({
    required this.cycleId,
    required this.startDate,
    this.endDate,
    this.cycleLengthDays = 28,
    this.periodDurationDays = 5,
    this.isOutlier = false,
    this.isOngoing = false,
    this.isUnrecordedGap = false,
    this.notes,
  });

  /// Salinan objek dengan beberapa properti yang dimodifikasi
  CycleModel copyWith({
    String? cycleId,
    DateTime? startDate,
    DateTime? endDate,
    int? cycleLengthDays,
    int? periodDurationDays,
    bool? isOutlier,
    bool? isOngoing,
    bool? isUnrecordedGap,
    String? notes,
  }) {
    return CycleModel(
      cycleId: cycleId ?? this.cycleId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cycleLengthDays: cycleLengthDays ?? this.cycleLengthDays,
      periodDurationDays: periodDurationDays ?? this.periodDurationDays,
      isOutlier: isOutlier ?? this.isOutlier,
      isOngoing: isOngoing ?? this.isOngoing,
      isUnrecordedGap: isUnrecordedGap ?? this.isUnrecordedGap,
      notes: notes ?? this.notes,
    );
  }
}

/// TypeAdapter Manual untuk CycleModel (TypeId: 1)
class CycleModelAdapter extends TypeAdapter<CycleModel> {
  @override
  final int typeId = 1;

  @override
  CycleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CycleModel(
      cycleId: fields[0] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(fields[1] as int),
      endDate: fields[2] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[2] as int)
          : null,
      cycleLengthDays: fields[3] as int? ?? 28,
      periodDurationDays: fields[4] as int? ?? 5,
      isOutlier: fields[5] as bool? ?? false,
      isOngoing: fields[6] as bool? ?? false,
      notes: fields[7] as String?,
      isUnrecordedGap: fields[8] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CycleModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.cycleId)
      ..writeByte(1)
      ..write(obj.startDate.millisecondsSinceEpoch)
      ..writeByte(2)
      ..write(obj.endDate?.millisecondsSinceEpoch)
      ..writeByte(3)
      ..write(obj.cycleLengthDays)
      ..writeByte(4)
      ..write(obj.periodDurationDays)
      ..writeByte(5)
      ..write(obj.isOutlier)
      ..writeByte(6)
      ..write(obj.isOngoing)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.isUnrecordedGap);
  }
}

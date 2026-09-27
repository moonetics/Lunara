import 'package:hive/hive.dart';

/// Model Konfigurasi Aplikasi Lunara (Hive TypeId: 0)
class AppConfigModel extends HiveObject {
  String perspective; // 'female_self' (Mandiri) atau 'male_helper' (Pria Membantu)
  String partnerName;
  bool isBiometricEnabled;
  int defaultCycleLength;
  int defaultPeriodDuration;
  bool isNotificationsEnabled;
  int notificationHour;
  int notificationMinute;
  bool isSoundEnabled;
  String appGoal; // 'health_tracking' (default) atau 'natural_contraception'

  AppConfigModel({
    this.perspective = 'female_self',
    this.partnerName = 'Pasangan',
    this.isBiometricEnabled = false,
    this.defaultCycleLength = 28,
    this.defaultPeriodDuration = 5,
    this.isNotificationsEnabled = true,
    this.notificationHour = 9,
    this.notificationMinute = 0,
    this.isSoundEnabled = true,
    this.appGoal = 'health_tracking',
  });

  bool get isMaleHelper => perspective == 'male_helper';
  bool get isNaturalContraception => appGoal == 'natural_contraception';
  bool get isPregnancyProgram => appGoal == 'pregnancy_program';
  bool get isHealthTracking => appGoal == 'health_tracking';
}

/// TypeAdapter Manual untuk AppConfigModel (TypeId: 0)
class AppConfigModelAdapter extends TypeAdapter<AppConfigModel> {
  @override
  final int typeId = 0;

  @override
  AppConfigModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppConfigModel(
      perspective: fields[0] as String? ?? 'female_self',
      partnerName: fields[1] as String? ?? 'Pasangan',
      isBiometricEnabled: fields[2] as bool? ?? false,
      defaultCycleLength: fields[3] as int? ?? 28,
      defaultPeriodDuration: fields[4] as int? ?? 5,
      isNotificationsEnabled: fields[5] as bool? ?? true,
      notificationHour: fields[6] as int? ?? 9,
      notificationMinute: fields[7] as int? ?? 0,
      isSoundEnabled: fields[8] as bool? ?? true,
      appGoal: fields[9] as String? ?? 'health_tracking',
    );
  }

  @override
  void write(BinaryWriter writer, AppConfigModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.perspective)
      ..writeByte(1)
      ..write(obj.partnerName)
      ..writeByte(2)
      ..write(obj.isBiometricEnabled)
      ..writeByte(3)
      ..write(obj.defaultCycleLength)
      ..writeByte(4)
      ..write(obj.defaultPeriodDuration)
      ..writeByte(5)
      ..write(obj.isNotificationsEnabled)
      ..writeByte(6)
      ..write(obj.notificationHour)
      ..writeByte(7)
      ..write(obj.notificationMinute)
      ..writeByte(8)
      ..write(obj.isSoundEnabled)
      ..writeByte(9)
      ..write(obj.appGoal);
  }
}

// ============= models/device_status.dart =============
class DeviceStatus {
  final String state;
  final bool motorRunning;
  final double targetLength;
  final double currentLength;
  final double progress;
  final int motorSpeed;
  final int currentMotorSpeed;
  final int speedAdjustment;
  final double diameter;
  final double offset;
  final int minStartSpeed;
  final int minStopSpeed;
  final String firmwareVersion;
  final bool wifiConnected;
  final bool emergencyStop;
  final int encoderErrors;
  final double? remainingCm;
  final int? estimatedSecondsRemaining;

  DeviceStatus({
    required this.state,
    required this.motorRunning,
    required this.targetLength,
    required this.currentLength,
    required this.progress,
    required this.motorSpeed,
    required this.currentMotorSpeed,
    required this.speedAdjustment,
    required this.diameter,
    required this.offset,
    required this.minStartSpeed,
    required this.minStopSpeed,
    required this.firmwareVersion,
    required this.wifiConnected,
    required this.emergencyStop,
    required this.encoderErrors,
    this.remainingCm,
    this.estimatedSecondsRemaining,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      state: json['state'] ?? 'UNKNOWN',
      motorRunning: json['motorRunning'] ?? false,
      targetLength: (json['targetLength'] ?? 0).toDouble(),
      currentLength: (json['currentLength'] ?? 0).toDouble(),
      progress: (json['progress'] ?? 0).toDouble(),
      motorSpeed: json['motorSpeed'] ?? 150,
      currentMotorSpeed: json['currentMotorSpeed'] ?? 150,
      speedAdjustment: json['speedAdjustment'] ?? 0,
      diameter: (json['diameter'] ?? 5.7).toDouble(),
      offset: (json['offset'] ?? 0).toDouble(),
      minStartSpeed: json['minStartSpeed'] ?? 150,
      minStopSpeed: json['minStopSpeed'] ?? 30,
      firmwareVersion: json['firmwareVersion'] ?? 'Unknown',
      wifiConnected: json['wifiConnected'] ?? false,
      emergencyStop: json['emergencyStop'] ?? false,
      encoderErrors: json['encoderErrors'] ?? 0,
      remainingCm: json['remainingCm']?.toDouble(),
      estimatedSecondsRemaining: json['estimatedSecondsRemaining'],
    );
  }

  DeviceStatus copyWith({
    String? state,
    bool? motorRunning,
    double? targetLength,
    double? currentLength,
    double? progress,
    int? motorSpeed,
    int? currentMotorSpeed,
    int? speedAdjustment,
    double? diameter,
    double? offset,
    int? minStartSpeed,
    int? minStopSpeed,
    String? firmwareVersion,
    bool? wifiConnected,
    bool? emergencyStop,
    int? encoderErrors,
    double? remainingCm,
    int? estimatedSecondsRemaining,
  }) {
    return DeviceStatus(
      state: state ?? this.state,
      motorRunning: motorRunning ?? this.motorRunning,
      targetLength: targetLength ?? this.targetLength,
      currentLength: currentLength ?? this.currentLength,
      progress: progress ?? this.progress,
      motorSpeed: motorSpeed ?? this.motorSpeed,
      currentMotorSpeed: currentMotorSpeed ?? this.currentMotorSpeed,
      speedAdjustment: speedAdjustment ?? this.speedAdjustment,
      diameter: diameter ?? this.diameter,
      offset: offset ?? this.offset,
      minStartSpeed: minStartSpeed ?? this.minStartSpeed,
      minStopSpeed: minStopSpeed ?? this.minStopSpeed,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      wifiConnected: wifiConnected ?? this.wifiConnected,
      emergencyStop: emergencyStop ?? this.emergencyStop,
      encoderErrors: encoderErrors ?? this.encoderErrors,
      remainingCm: remainingCm ?? this.remainingCm,
      estimatedSecondsRemaining: estimatedSecondsRemaining ?? this.estimatedSecondsRemaining,
    );
  }
}
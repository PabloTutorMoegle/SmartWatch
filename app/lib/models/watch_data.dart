class ImuData {
  final int ax, ay, az;
  final int gx, gy, gz;

  ImuData({required this.ax, required this.ay, required this.az, required this.gx, required this.gy, required this.gz});

  double get axG => ax / 16384.0;
  double get ayG => ay / 16384.0;
  double get azG => az / 16384.0;

  @override
  String toString() => 'IMU($ax,$ay,$az  $gx,$gy,$gz)';
}

class WatchTime {
  final int hours;
  final int minutes;
  final int seconds;

  WatchTime({required this.hours, required this.minutes, required this.seconds});

  String get formatted => '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

  @override
  String toString() => formatted;
}

class WatchState {
  ImuData? imu;
  double? temperature;
  WatchTime? time;
  int steps = 0;
  String? buttonState;
  bool connected = false;
  String deviceName = '';
}

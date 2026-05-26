const String serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
const String charImuUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
const String charTempUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a9';
const String charButtonUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26aa';
const String charCommandUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26ab';
const String charTimeUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26ac';
const String charStepsUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26ad';

const String targetDeviceName = 'SmartWatch-Pro';

const cmdShowTime = 0x01;
const cmdShowImu = 0x02;
const cmdScreenOff = 0x03;
const cmdVibrate = 0x04;
const cmdShowSteps = 0x05;
const cmdResetSteps = 0x06;
const cmdSendNotification = 0x0B;
const cmdClearNotifications = 0x0C;

List<int> buildSendNotification(String title, String text) {
  final titleBytes = List<int>.from(title.codeUnits);
  final textBytes = List<int>.from(text.codeUnits);
  final tlen = titleBytes.length > 19 ? 19 : titleBytes.length;
  final mlen = textBytes.length > 49 ? 49 : textBytes.length;
  return [
    cmdSendNotification,
    tlen,
    ...titleBytes.sublist(0, tlen),
    mlen,
    ...textBytes.sublist(0, mlen),
  ];
}

List<int> buildCommand(int cmd, [List<int>? data]) {
  final bytes = <int>[cmd];
  if (data != null) bytes.addAll(data);
  return bytes;
}

List<int> buildTimeCommand(int h, int m, int s) {
  return [cmdShowTime, h, m, s];
}

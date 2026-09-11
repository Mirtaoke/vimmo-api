enum AttendanceStatus { present, late, absent, earlyDeparture }

class AttendanceModel {
  const AttendanceModel({
    required this.userId,
    required this.employeeName,
    required this.date,
    required this.status,
    this.arrival,
    this.departure,
    this.isWifiVerified = false,
    this.isGpsVerified = false,
  });
  final String userId, employeeName;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime? arrival, departure;
  final bool isWifiVerified, isGpsVerified;
}

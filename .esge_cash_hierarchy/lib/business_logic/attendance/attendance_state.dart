class AttendanceState {
  const AttendanceState({
    this.isGpsVerified = false,
    this.isWifiVerified = false,
    this.isCheckedIn = false,
  });
  final bool isGpsVerified, isWifiVerified, isCheckedIn;
  AttendanceState copyWith({
    bool? isGpsVerified,
    bool? isWifiVerified,
    bool? isCheckedIn,
  }) => AttendanceState(
    isGpsVerified: isGpsVerified ?? this.isGpsVerified,
    isWifiVerified: isWifiVerified ?? this.isWifiVerified,
    isCheckedIn: isCheckedIn ?? this.isCheckedIn,
  );
}

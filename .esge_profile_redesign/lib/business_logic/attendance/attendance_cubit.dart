import 'package:flutter_bloc/flutter_bloc.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit() : super(const AttendanceState());
  void verifyLocation() =>
      emit(state.copyWith(isGpsVerified: true, isWifiVerified: true));
  void checkIn() {
    if (state.isGpsVerified && state.isWifiVerified) {
      emit(state.copyWith(isCheckedIn: true));
    }
  }
}

class AppointmentModel {
  const AppointmentModel({
    required this.id,
    required this.customer,
    required this.subject,
    required this.place,
    required this.startsAt,
    required this.commercial,
    this.checkedIn = false,
  });
  final String id, customer, subject, place, commercial;
  final DateTime startsAt;
  final bool checkedIn;
}

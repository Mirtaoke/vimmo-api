class DashboardState {
  const DashboardState({this.selectedIndex = 0});
  final int selectedIndex;
  DashboardState copyWith({int? selectedIndex}) =>
      DashboardState(selectedIndex: selectedIndex ?? this.selectedIndex);
}

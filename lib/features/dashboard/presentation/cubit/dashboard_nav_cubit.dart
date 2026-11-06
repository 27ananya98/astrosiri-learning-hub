import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardNavCubit extends Cubit<int> {
  DashboardNavCubit() : super(1);

  void setTab(int index) => emit(index);
  void goToHome() => emit(0);
  void goToSubjects() => emit(1);
  void goToProfile() => emit(2);
}

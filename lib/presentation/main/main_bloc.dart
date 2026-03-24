import 'package:bloc/bloc.dart';

class MainViewEvent {}

class SwitchTabEvent extends MainViewEvent {
  final int newTabIdx;

  SwitchTabEvent({required this.newTabIdx});
}

class MainViewState {
  final int selectedTabIdx;

  MainViewState({required this.selectedTabIdx});
}

class MainBloc extends Bloc<MainViewEvent, MainViewState> {
  MainBloc() : super(MainViewState(selectedTabIdx: 0)){
    on<SwitchTabEvent>((event, emit){
      if(event.newTabIdx != state.selectedTabIdx){
        emit(MainViewState(selectedTabIdx: event.newTabIdx));
      }
    });
  }
  
}
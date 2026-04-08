import 'package:bloc/bloc.dart';
import 'package:gallaerial/domain/entities/settings_model.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';
import 'package:gallaerial/domain/useCases/settings/get_settings_use_case.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/main.dart';

class MainViewEvent {}

class InitMainViewEvent extends MainViewEvent {}

class SwitchTabEvent extends MainViewEvent {
  final int newTabIdx;

  SwitchTabEvent({required this.newTabIdx});
}

class MainViewState {
  final int selectedTabIdx;
  final SettingsModel settings;

  MainViewState({required this.selectedTabIdx, required this.settings});
}

class MainBloc extends Bloc<MainViewEvent, MainViewState> {
  MainBloc() : super(MainViewState(selectedTabIdx: 0, settings: SettingsModel())){
    on<InitMainViewEvent>((event, emit) async {
      var resSettings = await service<GetSettingsUsecase>().call(NoParams());
      emit(MainViewState(selectedTabIdx: state.selectedTabIdx, settings: resSettings.fold((l) => SettingsModel(), (r) => r)));

       await emit.forEach<SettingsModel>(
        service<UserRepository>().settingsStream,
        onData: (updatedSettings) {
          return MainViewState(selectedTabIdx: state.selectedTabIdx, settings: updatedSettings);
        },
      );
    });
    on<SwitchTabEvent>((event, emit){
      if(event.newTabIdx != state.selectedTabIdx){
        emit(MainViewState(selectedTabIdx: event.newTabIdx, settings: state.settings));
      }
    });
  }
  
}
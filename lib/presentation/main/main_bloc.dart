import 'package:bloc/bloc.dart';
import 'package:gallaerial/domain/entities/settings_model.dart';
import 'package:gallaerial/domain/repositories/settings_repository.dart';
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
  MainBloc() : super(MainViewState(selectedTabIdx: 0, settings: SettingsModel(showNames: true, expandTags: true))) {
    
    on<InitMainViewEvent>((event, emit) async {
      await emit.forEach<SettingsModel>(
        dependencyService<SettingsRepository>().settingsStream,
        onData: (updatedSettings) {
          return MainViewState(
            selectedTabIdx: state.selectedTabIdx, 
            settings: updatedSettings
          );
        },
      );
    });

    on<SwitchTabEvent>((event, emit) {
      if(event.newTabIdx != state.selectedTabIdx) {
        emit(MainViewState(
          selectedTabIdx: event.newTabIdx, 
          settings: state.settings
        ));
      }
    });
  }
}
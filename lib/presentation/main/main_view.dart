import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/main.dart';
import 'package:gallaerial/presentation/tag_list/tag_list_view.dart';
import 'package:gallaerial/presentation/main/main_bloc.dart';
import 'package:gallaerial/presentation/video_list/video_list_view.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MainBloc>(
        create: (context) => service<MainBloc>(),
        child: BlocBuilder<MainBloc, MainViewState>(
          builder: (context, state) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(
              state.selectedTabIdx == 0 ? "Files" : "Labels",
              style: Theme.of(context).textTheme.headlineSmall,
          )),
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.selectedTabIdx,
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            destinations: const [
             NavigationDestination(icon: Icon(Icons.video_collection), label: "Files"),
             NavigationDestination(icon: Icon(Icons.label), label: "Labels"),
            ],
            onDestinationSelected: (idx) => context.read<MainBloc>().add(SwitchTabEvent(newTabIdx: idx))),
            
      body: state.selectedTabIdx == 0 ? const VideoListView() : const TagListView(),
        )));
  }
}

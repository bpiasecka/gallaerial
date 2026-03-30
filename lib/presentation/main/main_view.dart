import 'dart:math' as math;

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
            flexibleSpace: Image.asset("assets/icon/branding_wide_empty.jpeg", fit: BoxFit.fitWidth, alignment: Alignment(0, -0.8)),
            //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(
              state.selectedTabIdx == 0 ? "Files" : "Labels",
              style: Theme.of(context).textTheme.headlineSmall,
          )),
          bottomNavigationBar: SizedBox(height: 80, child: Stack(fit: StackFit.passthrough, children: [
            Image.asset("assets/icon/branding_wide_empty.jpeg", fit: BoxFit.fitWidth, alignment: Alignment(0, 0.8)),
            Align(alignment: Alignment.bottomCenter, child: NavigationBar(
              height: 70,
            selectedIndex: state.selectedTabIdx,
            backgroundColor: Colors.transparent,//Theme.of(context).colorScheme.inversePrimary,
            
            destinations: const [
             NavigationDestination(icon: Icon(Icons.video_collection), label: "Files"),
             NavigationDestination(icon: Icon(Icons.label), label: "Labels"),
            ],
            onDestinationSelected: (idx) => context.read<MainBloc>().add(SwitchTabEvent(newTabIdx: idx))))])),
            
      body: state.selectedTabIdx == 0 ? const VideoListView() : const TagListView(),
        )));
  }
}

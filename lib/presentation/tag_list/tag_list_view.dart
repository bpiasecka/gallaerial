import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/main.dart';
import 'package:gallaerial/presentation/tag_list/create_tag_dialog.dart';
import 'package:gallaerial/presentation/tag_list/tag_element.dart';
import 'package:gallaerial/presentation/tag_list/tag_list_bloc.dart';

class TagListView extends StatelessWidget {
  const TagListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TagListBloc>(
      create: (_) => dependencyService()..add(LoadTagsEvent()),
      child: BlocBuilder<TagListBloc, TagListViewState>(
        builder: (context, state) {
          return Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: ReorderableListView.builder(
                padding: const EdgeInsets.only(bottom: 65),
                itemCount: state.tags.length,
                itemBuilder: (context, idx) {
                  final tag = state.tags[idx];
                  return TagElement(
                    key: ValueKey(tag.id), 
                    tag: tag,
                  );
                },
                onReorder: (int oldIndex, int newIndex) {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }

                  final movedTag = state.tags[oldIndex];
                  context.read<TagListBloc>().add(
                    ChangeOrderEvent(tag: movedTag, newOrder: newIndex),
                  );
                },
                proxyDecorator: (Widget child, int index, Animation<double> animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (BuildContext context, Widget? proxyChild) {
                      final double animValue = Curves.easeInOut.transform(animation.value);
                      final double scale = 1.0 + (0.03 * animValue); 
                      
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withAlpha((animValue * 150).toInt()),
                                blurRadius: 15 * animValue,
                                spreadRadius: 2 * animValue,
                                offset: Offset(0, 8 * animValue),
                              )
                            ],
                          ),
                          child: proxyChild,
                        ),
                      );
                    },
                    child: child,
                  );
                },
              ),
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () => showDialog(
                context: context, 
                builder: (dialogContext) => CreateTagDialog(parentContext: context,),
              ),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}
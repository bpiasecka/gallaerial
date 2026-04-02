import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/domain/entities/filter_model.dart';
import 'package:gallaerial/domain/entities/sort_model.dart';
import 'package:gallaerial/extensions/color_extension.dart';
import 'package:gallaerial/presentation/video_list/video_list_bloc.dart';

class FilterSortAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FilterSortAppBar({super.key});

  @override
  Size get preferredSize => const Size(double.infinity, 40);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoListBloc, VideoListViewState>(
      builder: (context, state) {
        final hasActiveModifiers = _hasActiveFilters(state.filter) || _hasActiveSort(state.sort);

        return AppBar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withAlpha(150),
          actions: [
            if (hasActiveModifiers)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._buildTagPills(context, state),
                      if (state.filter.name != null && state.filter.name!.isNotEmpty)
                        _buildNamePill(context, state),
                      if (_hasActiveSort(state.sort)) 
                        _buildSortPill(context, state),
                    ],
                  ),
                ),
              ),

            Builder(
              builder: (drawerContext) => IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Text('Filter | Sort'),
                /*const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.filter_list_alt), Icon(Icons.sort)],
                ),*/
                onPressed: () => Scaffold.of(drawerContext).openEndDrawer(),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- LOGIC HELPERS ---

  bool _hasActiveFilters(FilterModel filter) {
    return (filter.tagIds != null && filter.tagIds!.isNotEmpty) ||
           (filter.name != null && filter.name!.isNotEmpty);
  }

  bool _hasActiveSort(SortModel sort) {
    return sort.dateParameter != DateSortParameter.none ||
           sort.durationParameter != DurationSortParameter.none;
  }

  String _getSortText(SortModel sort) {
    if (sort.dateParameter == DateSortParameter.newest) return 'Newest';
    if (sort.dateParameter == DateSortParameter.oldest) return 'Oldest';
    if (sort.durationParameter == DurationSortParameter.longest) return 'Longest';
    if (sort.durationParameter == DurationSortParameter.shortest) return 'Shortest';
    return '';
  }

  // --- WIDGET BUILDERS ---

  List<Widget> _buildTagPills(BuildContext context, VideoListViewState state) {
    if (state.filter.tagIds == null) return [];

    return state.filter.tagIds!.map((tagId) {
      final tag = state.allTags.firstWhereOrNull((t) => t.id == tagId);
      if (tag == null) return const SizedBox.shrink();

      return _FilterPill(
        text: tag.name,
        leading: Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tag.color.toColor(),
          ),
        ),
        onRemove: () {
          final updatedTagIds = List<String>.from(state.filter.tagIds!)..remove(tagId);
          final updatedFilter = FilterModel(
            name: state.filter.name,
            tagIds: updatedTagIds,
            alternativeTags: state.filter.alternativeTags,
          );
          context.read<VideoListBloc>().add(SetFilterAndSortEvent(filter: updatedFilter, sort: state.sort));
        },
      );
    }).toList();
  }

  Widget _buildNamePill(BuildContext context, VideoListViewState state) {
    return _FilterPill(
      text: '"${state.filter.name!}"',
      onRemove: () {
        final updatedFilter = FilterModel(
          name: null, 
          tagIds: state.filter.tagIds, 
          alternativeTags: state.filter.alternativeTags
        );
        context.read<VideoListBloc>().add(SetFilterAndSortEvent(filter: updatedFilter, sort: state.sort));
      },
    );
  }

  Widget _buildSortPill(BuildContext context, VideoListViewState state) {
    return _FilterPill(
      text: _getSortText(state.sort),
      leading: const Icon(Icons.sort, color: Colors.white, size: 14),
      onRemove: () {
        context.read<VideoListBloc>().add(SetFilterAndSortEvent(filter: state.filter, sort: SortModel.empty()));
      },
    );
  }
}

// --- REUSABLE UI COMPONENT ---

class _FilterPill extends StatelessWidget {
  final String text;
  final Widget? leading;
  final VoidCallback onRemove;

  const _FilterPill({
    required this.text,
    required this.onRemove,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2.0),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/domain/entities/filter_model.dart';
import 'package:gallaerial/domain/entities/sort_model.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/extensions/color_extension.dart';
import 'package:gallaerial/presentation/video_list/video_list_bloc.dart';

enum UnifiedSortOption { none, newest, oldest, longest, shortest }

class FilterSortSideMenu extends StatefulWidget {
  final FilterModel currentFilter;
  final SortModel currentSort;
  final List<TagEntity> allTags;

  const FilterSortSideMenu({
    super.key,
    required this.currentFilter,
    required this.currentSort,
    required this.allTags,
  });

  @override
  State<FilterSortSideMenu> createState() => _FilterSortSideMenuState();
}

class _FilterSortSideMenuState extends State<FilterSortSideMenu> {
  late TextEditingController _nameController;
  late List<String> _selectedTagIds;
  late bool _alternativeTags;
  late UnifiedSortOption _selectedSort;

  final Map<UnifiedSortOption, String> _sortNames = {
    UnifiedSortOption.newest: 'Newest first',
    UnifiedSortOption.oldest: 'Oldest first',
    UnifiedSortOption.longest: 'Longest first',
    UnifiedSortOption.shortest: 'Shortest first',
    UnifiedSortOption.none: 'None',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentFilter.name ?? '');
    _selectedTagIds = List.from(widget.currentFilter.tagIds ?? []);
    _alternativeTags = widget.currentFilter.alternativeTags;
    _selectedSort = _getInitialSortOption(widget.currentSort);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- CORE UI ---

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildSectionHeader('Filter', topPadding: 16),
                  _buildNameSearchField(),
                  const SizedBox(height: 16),
        
                  _buildAlternativeTagsSwitch(),
                  
                  Text('Labels', style: Theme.of(context).textTheme.titleMedium),
                  _buildLabelsList(),
                ],
              ),
            ),
            const Divider(height: 32),
        
            _buildSectionHeader('Sort'),
            _buildSortDropdown(),
        
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSectionHeader(String title, {double topPadding = 0}) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 12.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildNameSearchField() {
    return TextField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Search by Name',
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _buildLabelsList() {
    return Wrap(
      spacing: 5,
      children: widget.allTags.map((tag) {
        final isSelected = _selectedTagIds.contains(tag.id);
        
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Container(
                width: 15, height: 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: tag.color.toColor(), 
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 1,
                      spreadRadius: 0.001,
                      color: Theme.of(context).colorScheme.shadow.withAlpha(100),
                      offset: const Offset(0, 0),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 10, height: 1),
              Text(tag.name, style: Theme.of(context).textTheme.bodyLarge,),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: isSelected ? Colors.black : Colors.black26),
          ),
          selected: isSelected,
          selectedColor: Theme.of(context).colorScheme.inversePrimary.withAlpha(120),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTagIds.add(tag.id);
              } else {
                _selectedTagIds.remove(tag.id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildAlternativeTagsSwitch() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Match Any Label', style: Theme.of(context).textTheme.titleMedium,),
      subtitle: const Text('If off, must match ALL selected labels'),
      value: _alternativeTags,
      onChanged: (val) => setState(() => _alternativeTags = val),
    );
  }

  Widget _buildSortDropdown() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: IntrinsicWidth(
          child: DropdownButtonFormField<UnifiedSortOption>(
            initialValue: _selectedSort,
            isExpanded: false,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: UnifiedSortOption.values.map((option) {
              return DropdownMenuItem<UnifiedSortOption>(
                value: option,
                child: Text(_sortNames[option]!),
              );
            }).toList(),
            onChanged: (UnifiedSortOption? newValue) {
              if (newValue != null) {
                setState(() => _selectedSort = newValue);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearAll,
              child: const Text('Clear'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: _confirmAndClose,
              child: const Text('Confirm'),
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC HELPERS ---

  void _clearAll() {
    setState(() {
      _nameController.clear();
      _selectedTagIds.clear();
      _alternativeTags = false;
      _selectedSort = UnifiedSortOption.none;
    });
  }

  void _confirmAndClose() {
    final changedFilter = FilterModel(
      name: _nameController.text.trim(),
      tagIds: _selectedTagIds,
      alternativeTags: _alternativeTags,
    );

    final changedSort = _createSortModel();

    context.read<VideoListBloc>().add(
      SetFilterAndSortEvent(filter: changedFilter, sort: changedSort)
    );
    Navigator.of(context).pop();
  }

  UnifiedSortOption _getInitialSortOption(SortModel sort) {
    if (sort.dateParameter == DateSortParameter.newest) return UnifiedSortOption.newest;
    if (sort.dateParameter == DateSortParameter.oldest) return UnifiedSortOption.oldest;
    if (sort.durationParameter == DurationSortParameter.longest) return UnifiedSortOption.longest;
    if (sort.durationParameter == DurationSortParameter.shortest) return UnifiedSortOption.shortest;
    return UnifiedSortOption.none;
  }

  SortModel _createSortModel() {
    switch (_selectedSort) {
      case UnifiedSortOption.newest:
        return SortModel(dateParameter: DateSortParameter.newest, durationParameter: DurationSortParameter.none);
      case UnifiedSortOption.oldest:
        return SortModel(dateParameter: DateSortParameter.oldest, durationParameter: DurationSortParameter.none);
      case UnifiedSortOption.longest:
        return SortModel(dateParameter: DateSortParameter.none, durationParameter: DurationSortParameter.longest);
      case UnifiedSortOption.shortest:
        return SortModel(dateParameter: DateSortParameter.none, durationParameter: DurationSortParameter.shortest);
      case UnifiedSortOption.none:
        return SortModel.empty();
    }
  }
}
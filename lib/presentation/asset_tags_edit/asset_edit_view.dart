import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/main.dart';
import 'package:gallaerial/presentation/asset_tags_edit/asset_edit_bloc.dart';

class AssetEditView extends StatelessWidget {
  final UserAssetEntity initialAsset;

  const AssetEditView({super.key, required this.initialAsset});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => dependencyService<AssetEditBloc>()..add(InitWithAssetEvent(asset: initialAsset)),
      child: BlocBuilder<AssetEditBloc, AssetEditState>(
        builder: (context, state) {
          if (state.assetEntity == null) return const SizedBox.shrink();

          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
            title: Text(
              "Tap on tags to select",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              width: double.maxFinite, 
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: state.allTags!.length,
                itemBuilder: (context, index) {
                  final tag = state.allTags![index];
                  final isSelected = state.assetEntity!.tagIds.contains(tag.id);

                  return _tagCard(tag, isSelected, context);
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tagCard(TagEntity tag, bool isSelected, BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      elevation: isSelected ? 2 : 1,
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2.0,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.read<AssetEditBloc>().add(TagClickedEvent(tag: tag));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: tag.color.toColor(),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black12, 
                    width: 1
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  tag.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
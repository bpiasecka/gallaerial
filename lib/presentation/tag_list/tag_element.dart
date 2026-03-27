import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/useCases/tags/edit_tag_name_use_case.dart';
import 'package:gallaerial/main.dart';
import 'package:gallaerial/presentation/common/inline_editable_text.dart';
import 'package:gallaerial/presentation/tag_list/tag_list_bloc.dart';

class TagElement extends StatefulWidget {
  final TagEntity tag;

  const TagElement({super.key, required this.tag});

  @override
  State<StatefulWidget> createState() {
    return TagElementState();
  }
}


class TagElementState extends State<TagElement> {
  late Color editedColor;

  @override
  void initState() {
    editedColor = widget.tag.color.toColor()!;
    super.initState();
  }

  void _changeColor(Color color) {
    setState(() {
      editedColor = color;
    });
  }

  void _changeName(String name) {
    service<EditTagNameUseCase>().call(EditTagNameParams(
      newName: name,
      oldTag: widget.tag));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      shadowColor: Theme.of(context).colorScheme.shadow,
      elevation: 3,
      child: Row(
        children: [
          _colorButton(widget.tag),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 215),
            child: InlineEditableText(
              initialText: widget.tag.name,
              onTextChanged: _changeName,
              style: Theme.of(context).textTheme.bodyLarge,
              limit: 20)),
          Expanded(child: Container(height: 1)),
          IconButton(onPressed: () => confirmAndRemove(context), icon: const Icon(Icons.delete, color: Colors.black,)),
          ReorderableDragStartListener(
            index: widget.tag.order,
            child: const Padding(
              padding: EdgeInsets.only(right: 15.0),
              child: Icon(Icons.drag_handle, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

    void confirmAndRemove(BuildContext context){
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Remove Label'),
        content: const Text('Are you sure you want to remove this label?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); 
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TagListBloc>().add(RemoveTagEvent(tag: widget.tag));
              
              Navigator.of(dialogContext).pop(); 
            },
            child: const Text(
              'Remove',
            ),
          ),
        ],
      );
    },
  );
  }

  Widget _colorButton(TagEntity tag) {
    return GestureDetector(
        onTapUp: (_) => _pickColor(context),
        child: Padding(
            padding: const EdgeInsetsGeometry.all(15),
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.tag.color.toColor(),
                  boxShadow: [BoxShadow(blurRadius: 5, spreadRadius: 0.001, color: Theme.of(context).colorScheme.shadow.withAlpha(100), offset: const Offset(0, 2))]),
            )));
  }

  void _pickColor(BuildContext viewContext) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change color of your label'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: widget.tag.color.toColor()!,
            onColorChanged: _changeColor,
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Got it'),
            onPressed: () {
              viewContext.read<TagListBloc>().add(EditTagColorEvent(oldTag: widget.tag, color: editedColor));
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

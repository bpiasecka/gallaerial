import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gallaerial/presentation/common/inline_editable_text.dart';
import 'package:gallaerial/presentation/tag_list/tag_list_bloc.dart';

class CreateTagDialog extends StatefulWidget{

  final BuildContext parentContext;

  const CreateTagDialog({super.key, required this.parentContext});

  @override
  State<StatefulWidget> createState() {
    return CreateTagDialogState();
  }
}

class CreateTagDialogState extends State<CreateTagDialog>{

  Color color = Colors.white;
  String name = "";
  String hint = "New label name";
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return StatefulBuilder(
            builder: (BuildContext builderContext, StateSetter dialogSetState) {

              InlineEditableText _inlineEditableText = InlineEditableText(
                controller: _nameController,
                    initialText: name, 
                    hint: hint,
                    onTextChanged: (newText)=> dialogSetState(() => name = newText), 
                    style: Theme.of(context).textTheme.bodyLarge,);

            return AlertDialog(
              title: const Text('Create new label'),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              content:
                Row(children: [
                  colorButton((newColor) => dialogSetState(() => color = newColor)),
                  Expanded(child: _inlineEditableText
                  ),
                ],),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('Add'),
                  onPressed: () {
                    String finalName = _nameController.text;
                    widget.parentContext
                        .read<TagListBloc>()
                        .add(AddTagEvent(color: color, name: finalName.isEmpty ? "Label Name" : finalName));
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });

  }


    void pickColor(Function(Color) onColorPicked) {
    showDialog(
      context: widget.parentContext,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color!'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: color,
            onColorChanged: onColorPicked,
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Got it'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }


    Widget colorButton(Function(Color) onColorPicked) {
    return GestureDetector(
        onTapUp: (_) => pickColor(onColorPicked),
        child: Padding(
            padding: const EdgeInsetsGeometry.all(15),
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(blurRadius: 5, spreadRadius: 0.001, color: Theme.of(context).colorScheme.shadow.withAlpha(100), offset: const Offset(0, 2))]),
            )));
  }
  

}
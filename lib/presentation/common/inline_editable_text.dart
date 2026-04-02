import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class InlineEditableText extends StatefulWidget {
  final String initialText;
  final String? hint;
  final ValueChanged<String> onTextChanged;
  final TextStyle? style;
  final int? limit;
  final TextEditingController? controller;


  const InlineEditableText({
    super.key,
    required this.initialText,
    required this.onTextChanged,
    this.hint,
    this.style,
    this.limit,
    this.controller
  });

  @override
  State<InlineEditableText> createState() {
    return _InlineEditableTextState();
  } 
}

class _InlineEditableTextState extends State<InlineEditableText> {
  late bool _isEditing; 
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late StreamSubscription<bool> keyboardSubscription;


  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _isEditing = widget.initialText.isEmpty && widget.hint != null && widget.hint!.isNotEmpty;

    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription = keyboardVisibilityController.onChange.listen((bool visible) {
      if (!visible) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _submit(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant InlineEditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText) {
      _controller.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    if(widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    keyboardSubscription.cancel();
    super.dispose();
  }

  void _submit(String newValue) {
    setState(() {
      _isEditing = false;
    });
    if (newValue != widget.initialText) {
      widget.onTextChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: widget.style,
        //maxLines: 2,
        textInputAction: TextInputAction.done,
        inputFormatters: widget.limit != null 
          ? [LengthLimitingTextInputFormatter(widget.limit)] 
          : null,
        onSubmitted: _submit,
        onTapOutside: (PointerDownEvent event) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          hintText: widget.hint, 
        ),
      );
    }

    final bool isEmpty = widget.initialText.isEmpty;
    final String displayText = (isEmpty && widget.hint != null) ? widget.hint! : widget.initialText;
    
    final TextStyle? displayStyle = isEmpty 
        ? widget.style?.copyWith(color: widget.style?.color?.withAlpha(127) ?? Colors.grey) 
        : widget.style;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _isEditing = true;
          _controller.text = widget.initialText; 
        });
        _focusNode.requestFocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(
          displayText,
          style: displayStyle ?? (isEmpty ? const TextStyle(color: Colors.grey) : null),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
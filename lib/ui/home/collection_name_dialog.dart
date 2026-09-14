import 'package:flutter/material.dart';

/// 모음 이름을 묻는다. 비었거나 [takenNames]에 있는 이름이면 확인 버튼을 막는다. 취소하면 null.
Future<String?> askCollectionName(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required Set<String> takenNames,
  String initial = '',
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _CollectionNameDialog(
        title: title,
        confirmLabel: confirmLabel,
        takenNames: takenNames,
        initial: initial,
      ),
    );

class _CollectionNameDialog extends StatefulWidget {
  const _CollectionNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.takenNames,
    required this.initial,
  });

  final String title;
  final String confirmLabel;
  final Set<String> takenNames;
  final String initial;

  @override
  State<_CollectionNameDialog> createState() => _CollectionNameDialogState();
}

class _CollectionNameDialogState extends State<_CollectionNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  String get _name => _controller.text.trim();
  bool get _taken => widget.takenNames.contains(_name);
  bool get _valid => _name.isNotEmpty && !_taken;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_valid) Navigator.pop(context, _name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: '예: 1차 오디션, 워크숍',
            errorText: _taken ? '이미 있는 모음이에요' : null,
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(onPressed: _valid ? _submit : null, child: Text(widget.confirmLabel)),
        ],
      );
}

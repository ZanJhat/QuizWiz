import 'package:flutter/material.dart';

class ChooseOrderDialog extends StatelessWidget {
  const ChooseOrderDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Chọn thứ tự'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Theo thứ tự'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Ngẫu nhiên'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class LSPFeeConfirmationDialog extends StatelessWidget {
  const LSPFeeConfirmationDialog({super.key, required this.feeAmountSat});
  final int feeAmountSat;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Channel Creation Confirmation"),
      content: Text(
        "A new just-in-time channel will be created, and a minimum fee of $feeAmountSat sat will be applied. Are you okay with that?",
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text("No"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text("Yes"),
        ),
      ],
    );
  }
}

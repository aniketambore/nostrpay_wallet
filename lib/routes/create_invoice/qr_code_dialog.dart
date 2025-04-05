import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/invoice_qr.dart';

class QrCodeDialog extends StatefulWidget {
  final String receivePaymentResponse;
  final Function(dynamic result) _onFinish;

  const QrCodeDialog(
    this._onFinish, {
    super.key,
    required this.receivePaymentResponse,
  });

  @override
  State<StatefulWidget> createState() {
    return QrCodeDialogState();
  }
}

class QrCodeDialogState extends State<QrCodeDialog> {
  ModalRoute? _currentRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentRoute ??= ModalRoute.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Invoice'),
          Row(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
              IconButton(
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: widget.receivePaymentResponse));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Invoice data was copied to your clipboard.'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
              ),
            ],
          ),
        ],
      ),
      titlePadding: const EdgeInsets.fromLTRB(20.0, 22.0, 0.0, 8.0),
      contentPadding:
          const EdgeInsets.only(left: 0.0, right: 0.0, bottom: 20.0),
      children: [
        InvoiceQR(bolt11: widget.receivePaymentResponse),
        const Padding(padding: EdgeInsets.only(top: 16.0)),
        TextButton(
          onPressed: (() {
            onFinish(false);
          }),
          child: const Text(
            'Close',
            style: TextStyle(fontSize: 14.3),
          ),
        ),
      ],
    );
  }

  void onFinish(dynamic result) {
    debugPrint(
        "onFinish $result, mounted: $mounted, _currentRoute: ${_currentRoute?.isCurrent}");
    if (mounted && _currentRoute != null && _currentRoute!.isCurrent) {
      Navigator.removeRoute(context, _currentRoute!);
    }
    // Call the onFinish callback passed to the widget
    widget._onFinish(result);
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:qr_flutter/qr_flutter.dart';

class QRDialog extends StatefulWidget {
  const QRDialog({Key? key, required String data})
      : _data = data,
        super(key: key);

  final String _data;

  @override
  _QRDialogState createState() => _QRDialogState();
}

class _QRDialogState extends State<QRDialog> {
  late String _data;

  @override
  void initState() {
    _data = widget._data;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children:[
        Center(
          child: SizedBox(
              width: 200,
              height: 200,
              child: QrImage(
                data: _data,
                version: QrVersions.auto,
                size: 200
              )
          )
        )
      ],
      elevation: 10,
    );
  }
}
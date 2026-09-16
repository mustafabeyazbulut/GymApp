import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single 6-digit code entry dialog, used by any authenticated action that
/// requires proving control of the account's phone (freeze/reactivate) -
/// the actual sending of the code and the follow-up submit call are both the
/// caller's responsibility, this widget only collects the digits.
Future<String?> showOtpCodeDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String codeLabel,
  required String submitLabel,
  required String cancelLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _OtpCodeDialog(
      title: title,
      message: message,
      codeLabel: codeLabel,
      submitLabel: submitLabel,
      cancelLabel: cancelLabel,
    ),
  );
}

class _OtpCodeDialog extends StatefulWidget {
  const _OtpCodeDialog({
    required this.title,
    required this.message,
    required this.codeLabel,
    required this.submitLabel,
    required this.cancelLabel,
  });

  final String title;
  final String message;
  final String codeLabel;
  final String submitLabel;
  final String cancelLabel;

  @override
  State<_OtpCodeDialog> createState() => _OtpCodeDialogState();
}

class _OtpCodeDialogState extends State<_OtpCodeDialog> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(labelText: widget.codeLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        ValueListenableBuilder(
          valueListenable: _codeController,
          builder: (context, value, _) => TextButton(
            onPressed: value.text.length == 6 ? () => Navigator.of(context).pop(value.text) : null,
            child: Text(widget.submitLabel),
          ),
        ),
      ],
    );
  }
}

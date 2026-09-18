import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hesabın telefonuna sahip olunduğunun kanıtlanmasını gerektiren (dondurma/
/// yeniden etkinleştirme) her kimliği doğrulanmış eylem tarafından kullanılan
/// tek bir 6 haneli kod giriş diyaloğu — kodun gerçek gönderimi ve sonrasındaki
/// gönderme çağrısı çağıranın sorumluluğundadır, bu widget yalnızca rakamları
/// toplar.
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

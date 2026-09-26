import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../../l10n/generated/app_localizations.dart';
import '../phone/phone_country.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Uygulamadaki tüm telefon girişlerinin ortak alanı: solda ülke seçici
/// (bayrak + çevirme kodu), sağda ulusal numara. Kullanıcı "+90" yazmak
/// zorunda kalmaz; alan değeri HER ZAMAN E.164 biçiminde bildirir (ör.
/// "+905551234567") - backend ile sözleşme bu.
///
/// - Varsayılan ülke cihaz bölgesinden gelir, yoksa Türkiye.
/// - Başa yazılan 0 (ulusal önek) tolere edilir.
/// - "+" ile başlayan uluslararası bir numara yapıştırılırsa ülke otomatik
///   o numaranın ülkesine geçer.
/// - Geçerlilik ülkeye göre (uzunluk + biçim) phone_numbers_parser ile
///   kontrol edilir.
///
/// [allowEmail] açıkken alan "telefon veya e-posta" kabul eder (Giriş,
/// Şifremi Unuttum): metinde harf veya @ varsa e-posta sayılır, ülke seçici
/// gizlenir ve metin olduğu gibi bildirilir.
class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({
    required this.labelText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.isRequired = true,
    this.allowEmail = false,
    this.clearable = false,
    this.errorText,
    this.textInputAction,
    super.key,
  });

  final String labelText;

  /// Her değişiklikte çağrılır: geçerli bir numara için E.164, e-posta
  /// modunda kırpılmış metin; boş veya geçersizse null.
  final ValueChanged<String?>? onChanged;

  /// Klavyeden gönderildiğinde (veya [clearable] ile temizlendiğinde) aynı
  /// değerle çağrılır.
  final ValueChanged<String?>? onSubmitted;
  final bool enabled;
  final bool isRequired;
  final bool allowEmail;
  final bool clearable;

  /// Dışarıdan zorlanan hata (ör. Giriş'teki hatalı kimlik bilgisi vurgusu).
  final String? errorText;
  final TextInputAction? textInputAction;

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  static final _emailCharacters = RegExp(r'[@a-zA-Z]');

  final _controller = TextEditingController();
  late PhoneCountry _country =
      PhoneCountry.fromRegionOrDefault(WidgetsBinding.instance.platformDispatcher.locale.countryCode);

  bool get _isEmailMode => widget.allowEmail && _emailCharacters.hasMatch(_controller.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PhoneNumber? _parse(String raw) {
    final text = raw.replaceAll(' ', '');
    if (text.isEmpty) return null;
    try {
      final phone = text.startsWith('+')
          ? PhoneNumber.parse(text)
          : PhoneNumber.parse(text, destinationCountry: _country.isoCode);
      return phone.isValid() ? phone : null;
    } on PhoneNumberException {
      return null;
    }
  }

  String? get _value {
    final text = _controller.text.trim();
    if (text.isEmpty) return null;
    if (_isEmailMode) return text;
    return _parse(text)?.international;
  }

  void _handleChanged(String text) {
    // Uluslararası biçimde yapıştırılan numara: ülkeyi o numaranın ülkesine
    // çevir ve alanda sadece ulusal kısmı bırak.
    if (!_isEmailMode && text.trim().startsWith('+')) {
      final phone = _parse(text);
      final country = phone == null ? null : PhoneCountry.byIsoCode(phone.isoCode);
      if (phone != null && country != null) {
        _country = country;
        _controller.value = TextEditingValue(
          text: phone.nsn,
          selection: TextSelection.collapsed(offset: phone.nsn.length),
        );
      }
    }
    setState(() {});
    widget.onChanged?.call(_value);
  }

  String? _validate(String? _) {
    final l10n = AppLocalizations.of(context)!;
    final text = _controller.text.trim();
    if (text.isEmpty) return widget.isRequired ? l10n.commonFieldRequired : null;
    if (_isEmailMode) return null;
    return _parse(text) == null ? l10n.phoneInvalidError : null;
  }

  Future<void> _pickCountry() async {
    final selected = await showModalBottomSheet<PhoneCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (_) => _CountryPickerSheet(selected: _country),
    );
    if (selected == null || !mounted) return;
    setState(() => _country = selected);
    widget.onChanged?.call(_value);
  }

  void _clear() {
    _controller.clear();
    setState(() {});
    widget.onChanged?.call(null);
    widget.onSubmitted?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showCountry = !_isEmailMode;

    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: widget.allowEmail ? TextInputType.emailAddress : TextInputType.phone,
      textInputAction: widget.textInputAction ?? TextInputAction.done,
      autocorrect: false,
      inputFormatters: widget.allowEmail ? null : [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
      decoration: InputDecoration(
        labelText: widget.labelText,
        errorText: widget.errorText,
        prefixIcon: showCountry
            ? _CountryButton(
                country: _country,
                semanticsLabel: l10n.phoneCountryButtonLabel('+${_country.dialCode}'),
                onTap: widget.enabled ? _pickCountry : null,
              )
            : null,
        suffixIcon: widget.clearable && _controller.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear), onPressed: widget.enabled ? _clear : null)
            : null,
      ),
      validator: _validate,
      onChanged: _handleChanged,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(_value),
    );
  }
}

class _CountryButton extends StatelessWidget {
  const _CountryButton({required this.country, required this.semanticsLabel, required this.onTap});

  final PhoneCountry country;
  final String semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.xs),
              Text('+${country.dialCode}', style: textTheme.bodyLarge),
              const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.onBackgroundFaint),
              const SizedBox(width: AppSpacing.xs),
              Container(width: 1, height: 20, color: AppColors.border),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.selected});

  final PhoneCountry selected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  List<PhoneCountry> _filtered(String languageCode) {
    final query = _query.trim().toLowerCase().replaceAll('+', '');
    final countries = [...PhoneCountry.all]
      ..sort((a, b) => a.localizedName(languageCode).compareTo(b.localizedName(languageCode)));
    if (query.isEmpty) return countries;
    return countries
        .where((c) =>
            c.localizedName(languageCode).toLowerCase().contains(query) ||
            c.isoCode.name.toLowerCase() == query ||
            c.dialCode.startsWith(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final languageCode = Localizations.localeOf(context).languageCode;
    final countries = _filtered(languageCode);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
                child: Text(l10n.phoneCountryPickerTitle, style: textTheme.titleMedium),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: TextField(
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: l10n.phoneCountrySearchHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: countries.isEmpty
                    ? Center(
                        child: Text(
                          l10n.phoneCountryEmptyMessage,
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
                        ),
                      )
                    : ListView.builder(
                        itemCount: countries.length,
                        itemBuilder: (context, index) {
                          final country = countries[index];
                          final isSelected = country.isoCode == widget.selected.isoCode;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            leading: Text(country.flag, style: const TextStyle(fontSize: 22)),
                            title: Text(country.localizedName(languageCode), style: textTheme.bodyLarge),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+${country.dialCode}',
                                  style: textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundMuted),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  const Icon(Icons.check, size: 18, color: AppColors.primary),
                                ],
                              ],
                            ),
                            onTap: () => Navigator.of(context).pop(country),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

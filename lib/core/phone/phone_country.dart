import 'package:intl_phone_field/countries.dart' as country_data;
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Telefon alanının ülke seçicisinde gösterilen tek bir ülke.
///
/// İki kaynağı birleştirir: bayrak ve yerelleştirilmiş ülke adları için
/// intl_phone_field'ın saf veri listesi (sadece veri, widget'ı kullanılmıyor);
/// çevirme kodu, doğrulama ve E.164 dönüşümü için phone_numbers_parser'ın
/// libphonenumber metadata'sı. İkisinin ISO kodu eşleşmeyen ülkeler listeye
/// alınmaz - aksi halde seçilebilen ama doğrulanamayan bir ülke olurdu.
class PhoneCountry {
  const PhoneCountry._({
    required this.isoCode,
    required this.dialCode,
    required this.flag,
    required this.defaultName,
    required this.nameTranslations,
  });

  final IsoCode isoCode;
  // Başında + olmadan, ör. "90".
  final String dialCode;
  final String flag;
  final String defaultName;
  final Map<String, String> nameTranslations;

  String localizedName(String languageCode) => nameTranslations[languageCode] ?? defaultName;

  static final List<PhoneCountry> all = _buildAll();

  static List<PhoneCountry> _buildAll() {
    final isoByName = {for (final iso in IsoCode.values) iso.name: iso};
    final result = <PhoneCountry>[];
    final seen = <IsoCode>{};
    for (final country in country_data.countries) {
      final iso = isoByName[country.code];
      if (iso == null || !seen.add(iso)) continue;
      result.add(PhoneCountry._(
        isoCode: iso,
        dialCode: PhoneNumber(isoCode: iso, nsn: '').countryCode,
        flag: country.flag,
        defaultName: country.name,
        nameTranslations: country.nameTranslations,
      ));
    }
    return List.unmodifiable(result);
  }

  static PhoneCountry? byIsoCode(IsoCode isoCode) {
    for (final country in all) {
      if (country.isoCode == isoCode) return country;
    }
    return null;
  }

  /// Cihaz bölgesindeki ülke (ör. de_DE → Almanya); bölge yoksa veya
  /// desteklenmiyorsa Türkiye.
  static PhoneCountry fromRegionOrDefault(String? regionCode) {
    final upper = regionCode?.toUpperCase();
    for (final country in all) {
      if (country.isoCode.name == upper) return country;
    }
    return byIsoCode(IsoCode.TR)!;
  }
}

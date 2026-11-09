import 'package:xml/xml.dart';

import '../models/city.dart';
import '../models/forecast.dart';
import 'app_exception.dart';

/// Interpreta as respostas XML do CPTEC/INPE.
///
/// Todas as leituras são tolerantes a campos ausentes: o que faltar vira `null`.
/// XML malformado ou com raiz inesperada lança [AppException.invalid].
class CptecParser {
  static XmlDocument _parse(String body) {
    try {
      return XmlDocument.parse(body);
    } on XmlException {
      throw const AppException.invalid();
    }
  }

  static String? _text(XmlElement parent, String tag) {
    final el = parent.getElement(tag);
    final t = el?.innerText.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  static double? _number(XmlElement parent, String tag) {
    final t = _text(parent, tag);
    if (t == null) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  /// `<cidades><cidade><nome/><uf/><id/></cidade>...</cidades>`
  static List<City> parseCities(String body) {
    final root = _parse(body).rootElement;
    if (root.name.local != 'cidades') throw const AppException.invalid();

    final cities = <City>[];
    for (final el in root.findElements('cidade')) {
      final name = _text(el, 'nome');
      final id = int.tryParse(_text(el, 'id') ?? '');
      if (name == null || id == null) continue; // registro inválido: ignora
      cities.add(City(id: id, name: name, uf: _text(el, 'uf') ?? ''));
    }
    return cities;
  }

  /// `<cidade><nome/><uf/><atualizacao/><previsao><dia/><tempo/><maxima/>
  /// <minima/><iuv/></previsao>...</cidade>`
  static Forecast parseForecast(String body, {required int cityId}) {
    final root = _parse(body).rootElement;
    if (root.name.local != 'cidade') throw const AppException.invalid();

    final updated = _text(root, 'atualizacao');
    final days = <DailyForecast>[];
    for (final el in root.findElements('previsao')) {
      final rawDate = _text(el, 'dia');
      days.add(DailyForecast(
        rawDate: rawDate,
        date: rawDate == null ? null : DateTime.tryParse(rawDate),
        min: _number(el, 'minima'),
        max: _number(el, 'maxima'),
        conditionCode: _text(el, 'tempo'),
        uv: _number(el, 'iuv'),
      ));
    }

    return Forecast(
      cityId: cityId,
      cityName: _text(root, 'nome'),
      uf: _text(root, 'uf'),
      updatedAtRaw: updated,
      updatedAt: updated == null ? null : DateTime.tryParse(updated),
      days: days,
    );
  }
}

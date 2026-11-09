import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/city.dart';
import '../models/forecast.dart';
import 'app_exception.dart';
import 'cptec_parser.dart';

/// Cliente HTTP do serviço XML do CPTEC/INPE.
class CptecService {
  CptecService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // O serviço historicamente responde em HTTP; tentamos HTTPS primeiro.
  static const _bases = [
    'https://servicos.cptec.inpe.br/XML',
    'http://servicos.cptec.inpe.br/XML',
  ];
  static const _timeout = Duration(seconds: 15);

  static const _accents = {
    'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'õ': 'o', 'ô': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };

  /// O serviço responde em ISO-8859-1; a busca é enviada sem acentos.
  static String normalizeQuery(String input) {
    final lower = input.trim().toLowerCase();
    return lower.split('').map((ch) => _accents[ch] ?? ch).join();
  }

  Future<List<City>> searchCities(String name) async {
    final q = Uri.encodeComponent(normalizeQuery(name));
    final body = await _get('listaCidades?city=$q');
    final cities = CptecParser.parseCities(body);
    cities.sort((a, b) => a.name.compareTo(b.name));
    return cities;
  }

  Future<Forecast> fetchForecast(City city) async {
    final body = await _get('cidade/${city.id}/previsao.xml');
    final forecast = CptecParser.parseForecast(body, cityId: city.id);
    return forecast.copyWith(savedAt: DateTime.now());
  }

  Future<String> _get(String path) async {
    AppException? lastError;
    for (final base in _bases) {
      try {
        final response =
            await _client.get(Uri.parse('$base/$path')).timeout(_timeout);
        if (response.statusCode != 200) {
          lastError = AppException.unavailable(response.statusCode);
          continue;
        }
        return _decode(response.bodyBytes);
      } on AppException {
        rethrow;
      } catch (_) {
        // SocketException, ClientException, TimeoutException, TLS, etc.
        lastError = const AppException.network();
      }
    }
    throw lastError ?? const AppException.network();
  }

  static String _decode(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  void dispose() => _client.close();
}

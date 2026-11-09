import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/city.dart';
import '../models/forecast.dart';

/// Persistência local com `shared_preferences` (chave/valor, valores em JSON).
///
/// - `recent_cities`: últimas cidades consultadas (máx. 8)
/// - `last_city`: última cidade aberta
/// - `forecast_<id>`: última previsão recebida de cada cidade (cache offline)
class StorageService {
  static const _recentKey = 'recent_cities';
  static const _lastCityKey = 'last_city';
  static const _maxRecent = 8;

  static String _forecastKey(int cityId) => 'forecast_$cityId';

  Future<List<City>> loadRecentCities() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => City.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      await prefs.remove(_recentKey); // dado corrompido: descarta
      return [];
    }
  }

  Future<void> addRecentCity(City city) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadRecentCities();
    list.remove(city);
    list.insert(0, city);
    final trimmed = list.take(_maxRecent).toList();
    await prefs.setString(
        _recentKey, jsonEncode(trimmed.map((c) => c.toJson()).toList()));
    await prefs.setString(_lastCityKey, jsonEncode(city.toJson()));
  }

  Future<void> clearRecentCities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
    await prefs.remove(_lastCityKey);
  }

  Future<void> saveForecast(Forecast forecast) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _forecastKey(forecast.cityId), jsonEncode(forecast.toJson()));
  }

  Future<Forecast?> loadForecast(int cityId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_forecastKey(cityId));
    if (raw == null) return null;
    try {
      return Forecast.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      await prefs.remove(_forecastKey(cityId));
      return null;
    }
  }
}

/// Previsão de um único dia. Todos os campos são opcionais porque o serviço
/// pode omitir informações (o app nunca assume que existem).
class DailyForecast {
  final String? rawDate;
  final DateTime? date;
  final double? min;
  final double? max;

  /// Sigla da condição do tempo (ex.: "pn", "ec").
  final String? conditionCode;

  /// Índice ultravioleta, quando disponível.
  final double? uv;

  const DailyForecast({
    this.rawDate,
    this.date,
    this.min,
    this.max,
    this.conditionCode,
    this.uv,
  });

  Map<String, dynamic> toJson() => {
        'rawDate': rawDate,
        'min': min,
        'max': max,
        'code': conditionCode,
        'uv': uv,
      };

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    final raw = json['rawDate'] as String?;
    return DailyForecast(
      rawDate: raw,
      date: raw == null ? null : DateTime.tryParse(raw),
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      conditionCode: json['code'] as String?,
      uv: (json['uv'] as num?)?.toDouble(),
    );
  }
}

/// Previsão de quatro dias de uma cidade.
class Forecast {
  final int cityId;
  final String? cityName;
  final String? uf;

  /// Data de atualização informada pelo serviço.
  final String? updatedAtRaw;
  final DateTime? updatedAt;
  final List<DailyForecast> days;

  /// Momento em que o app salvou estes dados localmente (cache).
  final DateTime? savedAt;

  const Forecast({
    required this.cityId,
    this.cityName,
    this.uf,
    this.updatedAtRaw,
    this.updatedAt,
    this.days = const [],
    this.savedAt,
  });

  Forecast copyWith({DateTime? savedAt}) => Forecast(
        cityId: cityId,
        cityName: cityName,
        uf: uf,
        updatedAtRaw: updatedAtRaw,
        updatedAt: updatedAt,
        days: days,
        savedAt: savedAt ?? this.savedAt,
      );

  Map<String, dynamic> toJson() => {
        'cityId': cityId,
        'cityName': cityName,
        'uf': uf,
        'updatedAt': updatedAtRaw,
        'savedAt': savedAt?.toIso8601String(),
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory Forecast.fromJson(Map<String, dynamic> json) {
    final updated = json['updatedAt'] as String?;
    final saved = json['savedAt'] as String?;
    final days = (json['days'] as List? ?? const [])
        .whereType<Map>()
        .map((d) => DailyForecast.fromJson(Map<String, dynamic>.from(d)))
        .toList();
    return Forecast(
      cityId: json['cityId'] as int,
      cityName: json['cityName'] as String?,
      uf: json['uf'] as String?,
      updatedAtRaw: updated,
      updatedAt: updated == null ? null : DateTime.tryParse(updated),
      savedAt: saved == null ? null : DateTime.tryParse(saved),
      days: days,
    );
  }
}

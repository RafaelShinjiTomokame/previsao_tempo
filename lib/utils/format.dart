import '../models/forecast.dart';

const _weekdays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

String _two(int n) => n.toString().padLeft(2, '0');

/// dd/MM (ou o texto original, ou "—").
String shortDate(DailyForecast d) {
  final date = d.date;
  if (date != null) return '${_two(date.day)}/${_two(date.month)}';
  return d.rawDate ?? '—';
}

/// "ter, 10/11/2026"
String longDate(DailyForecast d) {
  final date = d.date;
  if (date == null) return d.rawDate ?? 'Data não informada';
  return '${_weekdays[date.weekday - 1]}, ${_two(date.day)}/${_two(date.month)}/${date.year}';
}

String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

String formatDateTime(DateTime d) =>
    '${formatDate(d)} ${_two(d.hour)}:${_two(d.minute)}';

/// "27°C" ou "—" quando ausente.
String temp(double? v) => v == null ? '—' : '${v.round()}°C';

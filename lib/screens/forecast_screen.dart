import 'package:flutter/material.dart';

import '../models/city.dart';
import '../models/forecast.dart';
import '../services/app_exception.dart';
import '../services/cptec_service.dart';
import '../services/storage_service.dart';
import '../services/weather_conditions.dart';
import '../utils/format.dart';
import '../widgets/temperature_chart.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({
    super.key,
    required this.city,
    required this.service,
    required this.storage,
  });

  final City city;
  final CptecService service;
  final StorageService storage;

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  Forecast? _forecast;
  bool _loading = true;
  String? _error;

  /// true quando o que está na tela veio do cache local, não do serviço.
  bool _fromCache = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Mostra o cache imediatamente (se houver) enquanto consulta o serviço.
    final cached = await widget.storage.loadForecast(widget.city.id);
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _forecast = cached;
        _fromCache = true;
      });
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fresh = await widget.service.fetchForecast(widget.city);
      if (fresh.days.isNotEmpty) await widget.storage.saveForecast(fresh);
      if (!mounted) return;
      setState(() {
        _forecast = fresh;
        _fromCache = false;
        _loading = false;
      });
    } on AppException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Ocorreu um erro inesperado ao consultar a previsão.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.city.label),
        actions: [
          IconButton(
            tooltip: 'Atualizar previsão',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    final forecast = _forecast;

    // Primeira consulta sem nada para mostrar.
    if (forecast == null) {
      if (_loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return _Message(
        icon: Icons.cloud_off,
        text: _error ?? 'Não foi possível obter a previsão.',
        onRetry: _load,
      );
    }

    final hasDays = forecast.days.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          if (_error != null) _Banner(text: _bannerText(), isError: true),
          _updatedInfo(forecast),
          if (!hasDays)
            const _Message(
              icon: Icons.info_outline,
              text: 'Não há previsão disponível para esta cidade no momento.',
            )
          else ...[
            for (final d in forecast.days) _DayCard(day: d),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Temperaturas (°C)',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    TemperatureChart(days: forecast.days),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Center(
            child: Text('Fonte dos dados: CPTEC/INPE',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _bannerText() {
    final saved = _forecast?.savedAt;
    final when = saved == null ? '' : ' (salvos em ${formatDateTime(saved)})';
    return '$_error\nExibindo os últimos dados armazenados$when.';
  }

  Widget _updatedInfo(Forecast f) {
    final updated = f.updatedAt != null
        ? formatDate(f.updatedAt!)
        : (f.updatedAtRaw ?? 'não informada');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        'Atualizado pelo serviço em: $updated'
        '${_fromCache && _error == null ? '  •  dados salvos' : ''}',
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final DailyForecast day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(conditionIcon(day.conditionCode),
                size: 40, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(longDate(day),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(describeCondition(day.conditionCode)),
                  if (day.uv != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('Índice UV: ${day.uv!.toStringAsFixed(day.uv! % 1 == 0 ? 0 : 1)}',
                          style: const TextStyle(fontSize: 13)),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(temp(day.max),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE64A19))),
                Text(temp(day.min),
                    style: const TextStyle(
                        fontSize: 16, color: Color(0xFF1976D2))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: isError ? scheme.errorContainer : scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(isError ? Icons.warning_amber : Icons.info_outline),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.black45),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

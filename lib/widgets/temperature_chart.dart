import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/forecast.dart';
import '../utils/format.dart';

/// Gráfico de linhas com as temperaturas mínima e máxima dos dias previstos.
class TemperatureChart extends StatelessWidget {
  const TemperatureChart({super.key, required this.days});

  final List<DailyForecast> days;

  static const _maxColor = Color(0xFFE64A19);
  static const _minColor = Color(0xFF1976D2);

  List<FlSpot> _spots(double? Function(DailyForecast) pick) {
    final spots = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      final v = pick(days[i]);
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final maxSpots = _spots((d) => d.max);
    final minSpots = _spots((d) => d.min);
    final all = [...maxSpots, ...minSpots];

    if (all.length < 2) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Dados insuficientes para montar o gráfico.'),
      );
    }

    final lo = all.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final hi = all.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    LineChartBarData line(List<FlSpot> spots, Color color) => LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        );

    const hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (days.length - 1).toDouble(),
                minY: (lo - 3).floorToDouble(),
                maxY: (hi + 3).ceilToDouble(),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: hidden,
                  rightTitles: hidden,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.round()}°',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (value != i.toDouble() ||
                            i < 0 ||
                            i >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(shortDate(days[i]),
                              style: const TextStyle(fontSize: 11)),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  if (maxSpots.isNotEmpty) line(maxSpots, _maxColor),
                  if (minSpots.isNotEmpty) line(minSpots, _minColor),
                ],
              ),
            ),
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: _maxColor, label: 'Máxima'),
            SizedBox(width: 24),
            _Legend(color: _minColor, label: 'Mínima'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 14, height: 4, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}

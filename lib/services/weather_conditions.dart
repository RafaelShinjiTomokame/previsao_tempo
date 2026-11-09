import 'package:flutter/material.dart';

/// Siglas de condição do tempo do CPTEC/INPE e suas descrições.
const Map<String, String> kConditionDescriptions = {
  'ec': 'Encoberto com chuvas isoladas',
  'ci': 'Chuvas isoladas',
  'c': 'Chuva',
  'in': 'Instável',
  'pp': 'Possibilidade de pancadas de chuva',
  'cm': 'Chuva pela manhã',
  'cn': 'Chuva à noite',
  'pt': 'Pancadas de chuva à tarde',
  'pm': 'Pancadas de chuva pela manhã',
  'np': 'Nublado e pancadas de chuva',
  'pc': 'Pancadas de chuva',
  'pn': 'Parcialmente nublado',
  'cv': 'Chuvisco',
  'ch': 'Chuvoso',
  't': 'Tempestade',
  'ps': 'Predomínio de sol',
  'e': 'Encoberto',
  'n': 'Nublado',
  'cl': 'Céu claro',
  'nv': 'Nevoeiro',
  'g': 'Geada',
  'ne': 'Neve',
  'nd': 'Não definido',
  'pnt': 'Pancadas de chuva à noite',
  'psc': 'Possibilidade de chuva',
  'pcm': 'Possibilidade de chuva pela manhã',
  'pct': 'Possibilidade de chuva à tarde',
  'pcn': 'Possibilidade de chuva à noite',
  'npt': 'Nublado com pancadas à tarde',
  'npn': 'Nublado com pancadas à noite',
  'ncn': 'Nublado com chuva à noite',
  'nct': 'Nublado com chuva à tarde',
  'ncm': 'Nublado com chuva pela manhã',
  'npm': 'Nublado com pancadas pela manhã',
  'npp': 'Nublado com possibilidade de chuva',
  'vn': 'Variação de nebulosidade',
  'ct': 'Chuva à tarde',
  'ppn': 'Possibilidade de pancadas de chuva à noite',
  'ppt': 'Possibilidade de pancadas de chuva à tarde',
  'ppm': 'Possibilidade de pancadas de chuva pela manhã',
};

/// Converte a sigla em descrição compreensível (nunca lança exceção).
String describeCondition(String? code) {
  final c = code?.trim().toLowerCase();
  if (c == null || c.isEmpty) return 'Condição não informada';
  return kConditionDescriptions[c] ?? 'Condição desconhecida ($c)';
}

const _sun = {'ps', 'cl'};
const _partly = {'pn', 'vn'};
const _cloud = {'n', 'e'};
const _rain = {
  'ci', 'c', 'cv', 'ch', 'cm', 'cn', 'ct', 'psc', 'pcm', 'pct', 'pcn', //
  'ncm', 'nct', 'ncn', 'npp',
};
const _showers = {
  'pp', 'pm', 'pt', 'pc', 'pnt', 'np', 'npt', 'npn', 'npm', 'ppn', 'ppt', //
  'ppm', 'in', 'ec',
};

/// Ícone representativo da condição do tempo.
IconData conditionIcon(String? code) {
  final c = code?.trim().toLowerCase() ?? '';
  if (_sun.contains(c)) return Icons.wb_sunny;
  if (_partly.contains(c)) return Icons.cloud_queue;
  if (_cloud.contains(c)) return Icons.cloud;
  if (_rain.contains(c)) return Icons.water_drop;
  if (_showers.contains(c)) return Icons.umbrella;
  if (c == 't') return Icons.thunderstorm;
  if (c == 'ne' || c == 'g') return Icons.ac_unit;
  if (c == 'nv') return Icons.foggy;
  return Icons.help_outline;
}

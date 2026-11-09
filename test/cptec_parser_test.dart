import 'package:flutter_test/flutter_test.dart';
import 'package:previsao_tempo/services/app_exception.dart';
import 'package:previsao_tempo/services/cptec_parser.dart';
import 'package:previsao_tempo/services/cptec_service.dart';
import 'package:previsao_tempo/services/weather_conditions.dart';

void main() {
  group('parseCities', () {
    test('lê nome, UF e id', () {
      const xml = '''<?xml version="1.0" encoding="ISO-8859-1"?>
<cidades>
  <cidade><nome>Campinas</nome><uf>SP</uf><id>2438</id></cidade>
  <cidade><nome>Campinas</nome><uf>GO</uf><id>1234</id></cidade>
</cidades>''';
      final cities = CptecParser.parseCities(xml);
      expect(cities.length, 2);
      expect(cities.first.name, 'Campinas');
      expect(cities.first.uf, 'SP');
      expect(cities.first.id, 2438);
    });

    test('lista vazia quando nenhuma cidade é encontrada', () {
      expect(CptecParser.parseCities('<cidades></cidades>'), isEmpty);
    });

    test('ignora registros sem id ou nome', () {
      const xml = '<cidades><cidade><nome>X</nome></cidade></cidades>';
      expect(CptecParser.parseCities(xml), isEmpty);
    });

    test('XML inválido lança AppException', () {
      expect(() => CptecParser.parseCities('<html>erro'),
          throwsA(isA<AppException>()));
    });

    test('raiz inesperada lança AppException', () {
      expect(() => CptecParser.parseCities('<erro/>'),
          throwsA(isA<AppException>()));
    });
  });

  group('parseForecast', () {
    test('lê quatro dias completos', () {
      const xml = '''<?xml version="1.0"?>
<cidade>
  <nome>Campinas</nome><uf>SP</uf><atualizacao>2026-11-09</atualizacao>
  <previsao><dia>2026-11-10</dia><tempo>pn</tempo><maxima>30</maxima><minima>19</minima><iuv>12.0</iuv></previsao>
  <previsao><dia>2026-11-11</dia><tempo>c</tempo><maxima>28</maxima><minima>18</minima><iuv>10.0</iuv></previsao>
  <previsao><dia>2026-11-12</dia><tempo>ec</tempo><maxima>27</maxima><minima>17</minima><iuv>9.0</iuv></previsao>
  <previsao><dia>2026-11-13</dia><tempo>ps</tempo><maxima>31</maxima><minima>16</minima><iuv>13.0</iuv></previsao>
</cidade>''';
      final f = CptecParser.parseForecast(xml, cityId: 2438);
      expect(f.days.length, 4);
      expect(f.cityName, 'Campinas');
      expect(f.updatedAtRaw, '2026-11-09');
      expect(f.days[0].max, 30);
      expect(f.days[0].min, 19);
      expect(f.days[0].uv, 12.0);
      expect(f.days[0].date, DateTime(2026, 11, 10));
      expect(f.days[1].conditionCode, 'c');
    });

    test('campos ausentes viram null sem lançar exceção', () {
      const xml = '''<cidade><nome>X</nome>
  <previsao><dia>2026-11-10</dia><tempo>pn</tempo></previsao>
</cidade>''';
      final f = CptecParser.parseForecast(xml, cityId: 1);
      expect(f.days.length, 1);
      expect(f.days.first.max, isNull);
      expect(f.days.first.min, isNull);
      expect(f.days.first.uv, isNull);
      expect(f.updatedAtRaw, isNull);
    });

    test('valores numéricos inválidos viram null', () {
      const xml = '''<cidade><previsao><dia>2026-11-10</dia>
<maxima>--</maxima><minima>abc</minima><iuv></iuv></previsao></cidade>''';
      final f = CptecParser.parseForecast(xml, cityId: 1);
      expect(f.days.first.max, isNull);
      expect(f.days.first.min, isNull);
      expect(f.days.first.uv, isNull);
    });

    test('sem <previsao> resulta em lista vazia', () {
      final f = CptecParser.parseForecast(
          '<cidade><nome>ND</nome><uf></uf><atualizacao></atualizacao></cidade>',
          cityId: 1);
      expect(f.days, isEmpty);
    });

    test('XML inválido lança AppException', () {
      expect(() => CptecParser.parseForecast('lixo', cityId: 1),
          throwsA(isA<AppException>()));
    });
  });

  group('condições do tempo', () {
    test('converte siglas conhecidas', () {
      expect(describeCondition('pn'), 'Parcialmente nublado');
      expect(describeCondition('PS'), 'Predomínio de sol');
    });

    test('trata sigla ausente ou desconhecida', () {
      expect(describeCondition(null), 'Condição não informada');
      expect(describeCondition('zzz'), contains('desconhecida'));
    });
  });

  test('normalizeQuery remove acentos', () {
    expect(CptecService.normalizeQuery('  São José '), 'sao jose');
  });
}

# Previsão do Tempo (CPTEC/INPE)

Aplicativo Flutter para consultar a previsão do tempo de cidades brasileiras, usando o serviço XML do **CPTEC/INPE**.

Atividade 2 – Programação para Dispositivos Móveis II – Fatec – Prof. Arley.

**Autor:** Rafael Shinji Tomokame

## Funcionalidades implementadas

**Pesquisa de cidades**
- Busca por nome no serviço `listaCidades?city=...`.
- Os resultados mostram nome e UF; o usuário escolhe a localidade desejada.
- O código usado na previsão é o `id` retornado pelo próprio serviço.
- Mensagem quando nenhuma cidade é encontrada.

**Previsão de quatro dias** (`cidade/{id}/previsao.xml`)
- Exibe todos os dias retornados, com: data, temperatura mínima e máxima (°C), descrição da condição, ícone e índice UV (somente quando disponível).
- Exibe a data de atualização informada pelo serviço.
- As siglas (`pn`, `ec`, `ps`...) são convertidas em descrições, conforme a tabela do CPTEC/INPE (`lib/services/weather_conditions.dart`).
- Gráfico de linhas com as temperaturas mínima e máxima.

**Atualização e tratamento de erros**
- Botão de atualizar na barra superior e _pull-to-refresh_.
- Indicador de carregamento durante as consultas.
- Tratamento de falha de conexão, _timeout_, serviço indisponível (HTTP ≠ 200) e XML inválido, sempre com mensagem amigável e botão "Tentar novamente".
- Mensagem adequada quando não há previsão disponível.
- Campos ausentes ou numéricos inválidos viram `null` no _parser_ e a tela exibe "—", sem encerrar o app.
- O CPTEC/INPE é identificado como fonte dos dados nas duas telas.

**Navegação:** `SearchScreen` (busca/recentes) → `ForecastScreen` (previsão), com `Navigator.push`.

## Como executar

Pré-requisito: [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.19 ou superior.

Este repositório contém `lib/`, `test/` e `pubspec.yaml`. As pastas de plataforma (`android/`, `ios/`...) são geradas pelo Flutter:

```bash
flutter create . --project-name previsao_tempo --platforms android,ios
flutter pub get
flutter run
```

**Android – tráfego HTTP:** o app tenta HTTPS primeiro e, se falhar, usa HTTP (o serviço do CPTEC historicamente responde em HTTP). Para o fallback funcionar no Android, em `android/app/src/main/AndroidManifest.xml` adicione `android:usesCleartextTraffic="true"` à tag `<application>`. No Android, a permissão `INTERNET` já vem no manifesto de _debug_; para _release_, adicione `<uses-permission android:name="android.permission.INTERNET"/>`.

Testes do _parser_ e das siglas:

```bash
flutter test
```

## Bibliotecas utilizadas

| Pacote | Uso |
| --- | --- |
| `http` | Requisições HTTP ao serviço do CPTEC/INPE |
| `xml` | Interpretação das respostas XML |
| `shared_preferences` | Persistência local |
| `fl_chart` | Gráfico de temperaturas |

## Estratégia de persistência local

Usa `shared_preferences` (chave/valor), com os dados serializados em JSON (`lib/services/storage_service.dart`):

- `recent_cities`: até 8 últimas cidades consultadas (exibidas na tela inicial, com opção "Limpar").
- `last_city`: última cidade aberta.
- `forecast_<id>`: última previsão recebida de cada cidade.

O cache de previsão funciona assim: ao abrir uma cidade, o app mostra imediatamente os dados salvos e consulta o serviço em seguida. Se a consulta falhar (sem internet, serviço fora do ar), os dados salvos continuam na tela com um aviso e a data em que foram armazenados. Dados corrompidos são descartados sem causar erro.

## Estrutura do projeto

```
lib/
  main.dart
  models/        city.dart, forecast.dart
  services/      cptec_service.dart (HTTP), cptec_parser.dart (XML),
                 storage_service.dart (persistência), weather_conditions.dart,
                 app_exception.dart
  screens/       search_screen.dart, forecast_screen.dart
  widgets/       temperature_chart.dart
  utils/         format.dart
test/            cptec_parser_test.dart
```

## Fonte dos dados

Centro de Previsão de Tempo e Estudos Climáticos (**CPTEC/INPE**) – http://servicos.cptec.inpe.br/XML/

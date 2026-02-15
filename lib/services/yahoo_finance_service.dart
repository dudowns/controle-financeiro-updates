import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class YahooFinanceService {
  static final YahooFinanceService _instance = YahooFinanceService._internal();
  factory YahooFinanceService() => _instance;
  YahooFinanceService._internal();

  final String _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';

  /// Busca o preço atual de um ativo
  Future<double?> getPrecoAtual(String ticker) async {
    try {
      // Para ações brasileiras, adicionar .SA
      final tickerFormatado = ticker.endsWith('.SA') ? ticker : '$ticker.SA';

      final url = '$_baseUrl/$tickerFormatado';
      debugPrint('🔍 Buscando preço: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Verifica se a resposta é válida
        if (data['chart']['result'] == null ||
            data['chart']['result'].isEmpty) {
          debugPrint('❌ Nenhum resultado para $ticker');
          return null;
        }

        final result = data['chart']['result'][0];
        final meta = result['meta'];

        // Tenta pegar o preço atual, se não tiver, pega o fechamento anterior
        final precoAtual = meta['regularMarketPrice'] ?? meta['previousClose'];

        if (precoAtual == null) {
          debugPrint('❌ Preço não disponível para $ticker');
          return null;
        }

        debugPrint('✅ $ticker: R\$ $precoAtual');
        return precoAtual.toDouble();
      } else {
        debugPrint('❌ Erro HTTP ${response.statusCode} para $ticker');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exceção ao buscar $ticker: $e');
      return null;
    }
  }

  /// Busca dados completos de um ativo (incluindo variação, volume, etc)
  Future<Map<String, dynamic>?> getDadosCompletos(String ticker) async {
    try {
      final tickerFormatado = ticker.endsWith('.SA') ? ticker : '$ticker.SA';
      final url = '$_baseUrl/$tickerFormatado?range=1mo&interval=1d';

      debugPrint('🔍 Buscando dados completos: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['chart']['result'] == null ||
            data['chart']['result'].isEmpty) {
          debugPrint('❌ Nenhum resultado para $ticker');
          return null;
        }

        final result = data['chart']['result'][0];
        final meta = result['meta'];

        // Extrai os dados disponíveis
        final dados = {
          'precoAtual': meta['regularMarketPrice']?.toDouble() ??
              meta['previousClose']?.toDouble() ??
              0,
          'variacaoDiaria': meta['regularMarketChange']?.toDouble() ?? 0,
          'variacaoPercentual':
              (meta['regularMarketChangePercent']?.toDouble() ?? 0) * 100,
          'precoAbertura': meta['regularMarketOpen']?.toDouble() ?? 0,
          'maximaDia': meta['regularMarketDayHigh']?.toDouble() ?? 0,
          'minimaDia': meta['regularMarketDayLow']?.toDouble() ?? 0,
          'volume': meta['regularMarketVolume']?.toInt() ?? 0,
          'nome': meta['longName'] ?? meta['shortName'] ?? ticker,
          'ultimaAtualizacao': DateTime.now().toIso8601String(),
        };

        debugPrint('✅ Dados obtidos para $ticker');
        return dados;
      }

      debugPrint('❌ Erro HTTP ${response.statusCode} para $ticker');
      return null;
    } catch (e) {
      debugPrint('❌ Exceção ao buscar dados completos: $e');
      return null;
    }
  }

  /// Busca dados históricos para gráficos
  Future<List<Map<String, dynamic>>?> getDadosHistoricos(
    String ticker, {
    int dias = 30,
  }) async {
    try {
      final tickerFormatado = ticker.endsWith('.SA') ? ticker : '$ticker.SA';
      final url = '$_baseUrl/$tickerFormatado?range=${dias}d&interval=1d';

      debugPrint('🔍 Buscando histórico ($dias dias): $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['chart']['result'] == null ||
            data['chart']['result'].isEmpty) {
          debugPrint('❌ Nenhum histórico para $ticker');
          return null;
        }

        final result = data['chart']['result'][0];
        final timestamps = result['timestamp'] as List?;
        final indicators = result['indicators']?['quote']?[0];

        if (timestamps == null || indicators == null) {
          debugPrint('❌ Dados históricos incompletos para $ticker');
          return null;
        }

        final precos = indicators['close'] as List?;

        if (precos == null) {
          debugPrint('❌ Preços históricos não disponíveis para $ticker');
          return null;
        }

        List<Map<String, dynamic>> historico = [];

        for (int i = 0; i < timestamps.length; i++) {
          if (i < precos.length && precos[i] != null) {
            final data =
                DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000);
            historico.add({
              'data': data,
              'preco': (precos[i] as num).toDouble(),
            });
          }
        }

        debugPrint('✅ Histórico obtido para $ticker: ${historico.length} dias');
        return historico;
      }

      debugPrint('❌ Erro HTTP ${response.statusCode} no histórico');
      return null;
    } catch (e) {
      debugPrint('❌ Exceção ao buscar histórico: $e');
      return null;
    }
  }

  /// Busca preços de múltiplos ativos em lote
  Future<Map<String, double>> getPrecosEmLote(List<String> tickers) async {
    final Map<String, double> resultados = {};

    debugPrint('🔍 Buscando preços em lote para ${tickers.length} ativos');

    for (var ticker in tickers) {
      final preco = await getPrecoAtual(ticker);
      if (preco != null) {
        resultados[ticker] = preco;
      }
      // Pequena pausa para não sobrecarregar a API
      await Future.delayed(const Duration(milliseconds: 300));
    }

    debugPrint('✅ Lote concluído: ${resultados.length} ativos atualizados');
    return resultados;
  }

  /// Verifica se um ativo existe no Yahoo Finance
  Future<bool> ativoExiste(String ticker) async {
    try {
      final tickerFormatado = ticker.endsWith('.SA') ? ticker : '$ticker.SA';
      final url = '$_baseUrl/$tickerFormatado';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['chart']['result'] != null &&
            data['chart']['result'].isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Formata ticker para o formato Yahoo
  String formatarTicker(String ticker) {
    if (ticker.endsWith('.SA')) return ticker;
    return '$ticker.SA';
  }
}

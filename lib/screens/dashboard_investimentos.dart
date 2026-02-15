import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardInvestimentosScreen extends StatefulWidget {
  const DashboardInvestimentosScreen({super.key});

  @override
  State<DashboardInvestimentosScreen> createState() =>
      _DashboardInvestimentosScreenState();
}

class _DashboardInvestimentosScreenState
    extends State<DashboardInvestimentosScreen> {
  final DBHelper db = DBHelper();
  List<Map<String, dynamic>> investimentos = [];
  List<Map<String, dynamic>> proventos = [];

  bool carregando = true;

  double patrimonioTotal = 0;
  double valorInvestido = 0;
  double ganhoCapital = 0;
  double dividendosRecebidos = 0;
  double proventos12Meses = 0;

  final Map<String, double> valorPorTipo = {};

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    setState(() => carregando = true);

    investimentos = await db.getAllInvestimentos();
    proventos = await db.getAllProventos();

    _calcularEstatisticas();

    setState(() => carregando = false);
  }

  void _calcularEstatisticas() {
    patrimonioTotal = 0;
    valorInvestido = 0;
    dividendosRecebidos = 0;
    proventos12Meses = 0;
    valorPorTipo.clear();

    final agora = DateTime.now();
    final umAnoAtras = DateTime(agora.year - 1, agora.month, agora.day);

    for (var item in investimentos) {
      final precoAtual = (item['preco_atual'] ?? item['preco_medio']) as num;
      final quantidade = (item['quantidade'] ?? 0) as num;
      final precoMedio = (item['preco_medio'] ?? 0) as num;

      final valorAtual = precoAtual.toDouble() * quantidade.toDouble();
      final investido = precoMedio.toDouble() * quantidade.toDouble();

      patrimonioTotal += valorAtual;
      valorInvestido += investido;

      final tipo = item['tipo'] as String? ?? 'OUTROS';
      valorPorTipo[tipo] = (valorPorTipo[tipo] ?? 0) + valorAtual;
    }

    for (var p in proventos) {
      final dataString = p['data_pagamento'] as String? ?? '';
      final valor = (p['total_recebido'] ?? 0) as num;

      try {
        final data = DateTime.parse(dataString);
        final valorDouble = valor.toDouble();

        dividendosRecebidos += valorDouble;

        if (data.isAfter(umAnoAtras)) {
          proventos12Meses += valorDouble;
        }
      } catch (e) {
        // Ignora datas inválidas
      }
    }

    ganhoCapital = patrimonioTotal - valorInvestido;
  }

  String _formatarValor(double valor) {
    final formatador = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatador.format(valor);
  }

  String _formatarPercentual(double valor) {
    return '${valor.toStringAsFixed(2).replaceAll('.', ',')}%';
  }

  String _formatarEixoY(double value) {
    if (value >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(1)}k';
    }
    return 'R\$ ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Dashboard Investimentos'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: carregarDados,
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCardPatrimonio(),
                  const SizedBox(height: 16),
                  _buildCardLucro(),
                  const SizedBox(height: 16),
                  _buildCardProventos(),
                  const SizedBox(height: 16),
                  _buildGraficoEvolucao(),
                  const SizedBox(height: 16),
                  _buildCardAlocacao(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildCardPatrimonio() {
    final variacaoPercentual =
        valorInvestido > 0 ? (ganhoCapital / valorInvestido) * 100 : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PATRIMÔNIO TOTAL',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              _formatarValor(patrimonioTotal),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (variacaoPercentual >= 0 ? Colors.green : Colors.red)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        variacaoPercentual >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 14,
                        color: variacaoPercentual >= 0
                            ? Colors.green[200]
                            : Colors.red[200],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${variacaoPercentual >= 0 ? '+' : ''}${_formatarPercentual(variacaoPercentual)}',
                        style: TextStyle(
                          color: variacaoPercentual >= 0
                              ? Colors.green[200]
                              : Colors.red[200],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Investido: ${_formatarValor(valorInvestido)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardLucro() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LUCRO TOTAL',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Ganho Capital',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(
                        _formatarValor(ganhoCapital),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ganhoCapital >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    children: [
                      Text('Dividendos',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(
                        _formatarValor(dividendosRecebidos),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total acumulado:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    _formatarValor(ganhoCapital + dividendosRecebidos),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF6A1B9A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardProventos() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROVENTOS (12M)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text(
                    _formatarValor(proventos12Meses),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A1B9A)),
                  ),
                  const SizedBox(height: 4),
                  Text('Total: ${_formatarValor(dividendosRecebidos)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.monetization_on,
                  color: Color(0xFF6A1B9A), size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoEvolucao() {
    // Dados reais baseados nos investimentos
    final List<double> valorAplicado = [];
    final List<double> ganhoCapitalList = [];
    final List<String> meses = [];

    // Aqui você pode implementar a lógica para pegar dados reais
    // Por enquanto, vamos usar dados de exemplo
    for (int i = 0; i < 6; i++) {
      final mes = DateTime.now().subtract(Duration(days: 30 * (5 - i)));
      meses.add(DateFormat('MM/yy').format(mes));
      valorAplicado.add(valorInvestido * (0.8 + i * 0.04)); // Exemplo
      ganhoCapitalList.add(ganhoCapital * (0.5 + i * 0.1)); // Exemplo
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evolução do Patrimônio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData:
                      const FlGridData(show: true, drawVerticalLine: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatarEixoY(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 45,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < meses.length) {
                            return Text(
                              meses[value.toInt()],
                              style: const TextStyle(fontSize: 9),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 22,
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey[300]!, width: 1)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(valorAplicado.length,
                          (i) => FlSpot(i.toDouble(), valorAplicado[i])),
                      isCurved: true,
                      color: const Color(0xFF6A1B9A),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: List.generate(ganhoCapitalList.length,
                          (i) => FlSpot(i.toDouble(), ganhoCapitalList[i])),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendaCor('Valor aplicado', const Color(0xFF6A1B9A)),
                const SizedBox(width: 20),
                _buildLegendaCor('Ganho capital', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendaCor(String texto, Color cor) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCardAlocacao() {
    final total = valorPorTipo.values.fold(0.0, (a, b) => a + b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alocação por Tipo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...valorPorTipo.entries.map((entry) {
              final percentual = total > 0 ? (entry.value / total) * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_getNomeTipo(entry.key),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text(_formatarPercentual(percentual),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentual / 100,
                      backgroundColor: Colors.grey[200],
                      color: _getCorTipo(entry.key),
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _getNomeTipo(String tipo) {
    switch (tipo) {
      case 'ACAO':
        return '📈 Ações';
      case 'FII':
        return '🏢 FIIs';
      case 'RENDA_FIXA':
        return '💰 Renda Fixa';
      case 'CRIPTO':
        return '🪙 Cripto';
      default:
        return tipo;
    }
  }

  Color _getCorTipo(String tipo) {
    switch (tipo) {
      case 'ACAO':
        return Colors.blue;
      case 'FII':
        return Colors.green;
      case 'RENDA_FIXA':
        return Colors.orange;
      case 'CRIPTO':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

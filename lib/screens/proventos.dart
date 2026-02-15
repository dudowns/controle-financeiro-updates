import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';
import 'editar_provento.dart';
import 'adicionar_provento.dart';

class ProventosScreen extends StatefulWidget {
  const ProventosScreen({super.key});

  @override
  State<ProventosScreen> createState() => _ProventosScreenState();
}

class _ProventosScreenState extends State<ProventosScreen> {
  final DBHelper db = DBHelper();
  List<Map<String, dynamic>> proventos = [];
  List<Map<String, dynamic>> investimentos = [];
  bool carregando = true;

  double totalProventos = 0;
  double proventosMes = 0;
  double proventosAno = 0;
  Map<String, double> proventosPorTicker = {};
  Map<String, double> proventosPorMes = {};
  List<String> meses = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => carregando = true);

    proventos = await db.getAllProventos();
    investimentos = await db.getAllInvestimentos();
    _calcularEstatisticas();

    setState(() => carregando = false);
  }

  void _calcularEstatisticas() {
    totalProventos = 0;
    proventosMes = 0;
    proventosAno = 0;
    proventosPorTicker.clear();
    proventosPorMes.clear();

    final agora = DateTime.now();
    final inicioMes = DateTime(agora.year, agora.month, 1);
    final inicioAno = DateTime(agora.year, 1, 1);

    meses.clear();
    for (int i = 5; i >= 0; i--) {
      final data = DateTime(agora.year, agora.month - i, 1);
      final chave = DateFormat('MM/yyyy').format(data);
      meses.add(DateFormat('MMM').format(data));
      proventosPorMes[chave] = 0;
    }

    for (var p in proventos) {
      final valor = (p['total_recebido'] ?? 0).toDouble();
      final ticker = p['ticker'] ?? '';
      final dataPagamento = DateTime.parse(p['data_pagamento']);

      totalProventos += valor;

      if (dataPagamento.isAfter(inicioMes) ||
          dataPagamento.isAtSameMomentAs(inicioMes)) {
        proventosMes += valor;
      }

      if (dataPagamento.isAfter(inicioAno) ||
          dataPagamento.isAtSameMomentAs(inicioAno)) {
        proventosAno += valor;
      }

      proventosPorTicker[ticker] = (proventosPorTicker[ticker] ?? 0) + valor;

      final chaveMes = DateFormat('MM/yyyy').format(dataPagamento);
      proventosPorMes[chaveMes] = (proventosPorMes[chaveMes] ?? 0) + valor;
    }
  }

  List<Map<String, dynamic>> _getProximosProventos() {
    final hoje = DateTime.now();
    final proximos = proventos.where((p) {
      try {
        final data = DateTime.parse(p['data_pagamento']);
        return data.isAfter(hoje);
      } catch (e) {
        return false;
      }
    }).toList();

    proximos.sort((a, b) {
      final dataA = DateTime.parse(a['data_pagamento']);
      final dataB = DateTime.parse(b['data_pagamento']);
      return dataA.compareTo(dataB);
    });

    return proximos.take(5).toList();
  }

  String _formatarValor(double valor) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
    ).format(valor);
  }

  String _formatarData(String dataString) {
    try {
      final data = DateTime.parse(dataString);
      return DateFormat('dd/MM/yyyy').format(data);
    } catch (e) {
      return dataString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Proventos'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : proventos.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6A1B9A),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdicionarProventoScreen(),
            ),
          );
          if (result == true) {
            _carregarDados();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6A1B9A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.monetization_on,
                size: 64, color: Color(0xFF6A1B9A)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhum provento registrado',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E2F)),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para adicionar seu primeiro provento',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final proximos = _getProximosProventos();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildResumoCard(
                  'Total',
                  _formatarValor(totalProventos),
                  Icons.account_balance_wallet,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildResumoCard(
                  'Este mês',
                  _formatarValor(proventosMes),
                  Icons.calendar_today,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildResumoCard(
                  'Este ano',
                  _formatarValor(proventosAno),
                  Icons.calendar_view_month,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (proximos.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.event_available,
                            color: Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '📅 Próximos Proventos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...proximos.map((p) => _buildProximoItem(p)).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Text(
            'Histórico de Proventos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...proventos.map((p) => _buildProventoCard(p)).toList(),
        ],
      ),
    );
  }

  Widget _buildResumoCard(
      String titulo, String valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: cor, size: 16),
              const SizedBox(width: 4),
              Text(
                titulo,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProximoItem(Map<String, dynamic> p) {
    final data = DateTime.parse(p['data_pagamento']);
    final diasRestantes = data.difference(DateTime.now()).inDays;
    final isRendaFixa = p['tipo_provento'] == 'Renda Fixa';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditarProventoScreen(provento: p),
          ),
        );
        if (result == true) {
          _carregarDados();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isRendaFixa
                    ? Colors.teal.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isRendaFixa ? Icons.savings : Icons.trending_up,
                color: isRendaFixa ? Colors.teal : Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['ticker'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(data)} • $diasRestantes dias',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatarValor(p['total_recebido']?.toDouble() ?? 0),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isRendaFixa ? Colors.teal : Colors.green,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'em $diasRestantes dias',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProventoCard(Map<String, dynamic> item) {
    final isRendaFixa = item['tipo_provento'] == 'Renda Fixa';
    final cor = isRendaFixa
        ? Colors.teal
        : (item['ticker']?.contains('11') ?? false
            ? Colors.green
            : Colors.blue);
    final icone = isRendaFixa
        ? Icons.savings
        : (item['ticker']?.contains('11') ?? false
            ? Icons.apartment
            : Icons.trending_up);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icone, color: cor, size: 24),
        ),
        title: Text(
          item['ticker'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item['tipo_provento'] ?? 'Dividendo'} • ${_formatarData(item['data_pagamento'])}',
            ),
            Text(
              '${item['quantidade'] ?? 1} cotas • R\$ ${(item['valor_por_cota'] ?? 0).toStringAsFixed(2)}/cota',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        trailing: Text(
          _formatarValor(item['total_recebido']?.toDouble() ?? 0),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditarProventoScreen(provento: item),
            ),
          );
          if (result == true) {
            _carregarDados();
          }
        },
      ),
    );
  }
}

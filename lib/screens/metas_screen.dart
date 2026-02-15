import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';
import 'nova_meta_screen.dart';
import 'detalhes_meta_screen.dart';

class MetasScreen extends StatefulWidget {
  const MetasScreen({super.key});

  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen> {
  final DBHelper db = DBHelper();
  List<Map<String, dynamic>> metas = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarMetas();
  }

  Future<void> _carregarMetas() async {
    setState(() => carregando = true);
    metas = await db.getAllMetas();
    setState(() => carregando = false);
  }

  String _formatarValor(double valor) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
    ).format(valor);
  }

  Color _getCorPorTipo(String? cor) {
    switch (cor) {
      case 'viagem':
        return Colors.blue;
      case 'carro':
        return Colors.red;
      case 'casa':
        return Colors.green;
      case 'estudo':
        return Colors.orange;
      case 'investimento':
        return Colors.purple;
      default:
        return const Color(0xFF6A1B9A);
    }
  }

  IconData _getIconePorTipo(String? icone) {
    switch (icone) {
      case 'viagem':
        return Icons.flight;
      case 'carro':
        return Icons.directions_car;
      case 'casa':
        return Icons.home;
      case 'estudo':
        return Icons.school;
      case 'investimento':
        return Icons.trending_up;
      default:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Metas'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarMetas,
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : metas.isEmpty
              ? _buildEmptyState()
              : _buildList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6A1B9A),
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NovaMetaScreen(),
            ),
          );
          if (result == true) {
            _carregarMetas();
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
            child: const Icon(Icons.flag, size: 64, color: Color(0xFF6A1B9A)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhuma meta cadastrada',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E2F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para criar sua primeira meta',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: metas.length,
      itemBuilder: (context, index) {
        final meta = metas[index];
        final valorObjetivo = (meta['valor_objetivo'] ?? 0).toDouble();
        final valorAtual = (meta['valor_atual'] ?? 0).toDouble();
        final progresso = valorObjetivo > 0 ? valorAtual / valorObjetivo : 0.0;
        final percentual = (progresso * 100).clamp(0, 100);
        final cor = _getCorPorTipo(meta['cor']);
        final icone = _getIconePorTipo(meta['icone']);
        final concluida = meta['concluida'] == 1;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalhesMetaScreen(meta: meta),
                ),
              );
              if (result == true) {
                _carregarMetas();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: concluida
                    ? Border.all(color: Colors.green, width: 2)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icone, color: cor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meta['titulo'] ?? 'Sem título',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (meta['descricao'] != null &&
                                meta['descricao'].toString().isNotEmpty)
                              Text(
                                meta['descricao'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (concluida)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Concluída',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'R\$ ${_formatarValor(valorAtual)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'de R\$ ${_formatarValor(valorObjetivo)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${percentual.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: percentual >= 100
                              ? Colors.green
                              : const Color(0xFF6A1B9A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progresso.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[200],
                      color: percentual >= 100 ? Colors.green : cor,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (meta['data_fim'] != null)
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(DateTime.parse(meta['data_fim'])),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Faltam R\$ ${_formatarValor((valorObjetivo - valorAtual).clamp(0, valorObjetivo))}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

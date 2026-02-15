import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../services/yahoo_finance_service.dart';
import '../services/notification_service.dart';
import 'detalhes_ativo.dart';
import 'grafico_ativo.dart';
import 'package:intl/intl.dart';

class InvestimentosScreen extends StatefulWidget {
  const InvestimentosScreen({super.key});

  @override
  State<InvestimentosScreen> createState() => _InvestimentosScreenState();
}

class _InvestimentosScreenState extends State<InvestimentosScreen> {
  final DBHelper db = DBHelper();
  List<Map<String, dynamic>> investimentos = [];
  bool carregando = true;
  bool atualizando = false;

  final Map<String, Color> coresPorTipo = {
    'ACAO': Colors.blue,
    'FII': Colors.green,
    'ETF': Colors.purple,
    'BDR': Colors.orange,
    'CRIPTO': Colors.amber,
  };

  @override
  void initState() {
    super.initState();
    carregarInvestimentos();
  }

  Future<void> carregarInvestimentos() async {
    setState(() => carregando = true);
    final dados = await db.getAllInvestimentos();
    setState(() {
      investimentos = dados;
      carregando = false;
    });
  }

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarQuantidade(double valor) {
    return valor.toStringAsFixed(0);
  }

  double _calcularVariacao(double precoAtual, double precoMedio) {
    if (precoAtual == 0 || precoMedio == 0) return 0;
    return ((precoAtual - precoMedio) / precoMedio) * 100;
  }

  Future<void> _atualizarPrecos() async {
    setState(() => atualizando = true);

    int atualizados = 0;
    int comErro = 0;
    final service = YahooFinanceService();

    for (var item in investimentos) {
      try {
        final preco = await service.getPrecoAtual(item['ticker']);
        if (preco != null && preco > 0) {
          await db.updatePrecoAtual(item['id'], preco);
          atualizados++;
        } else {
          comErro++;
        }
      } catch (e) {
        comErro++;
      }
    }

    await carregarInvestimentos();
    setState(() => atualizando = false);

    await NotificationService().addNotification(
      titulo: '📊 Preços Atualizados',
      mensagem:
          '$atualizados ativos atualizados com sucesso${comErro > 0 ? ', $comErro falharam' : ''}!',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$atualizados ativos atualizados${comErro > 0 ? ', $comErro erros' : ''}'),
          backgroundColor: comErro > 0 ? Colors.orange : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Investimentos'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: atualizando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: atualizando ? null : _atualizarPrecos,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              if (investimentos.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Adicione investimentos primeiro'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GraficoAtivoScreen(ativo: investimentos.first),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Container(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          carregando
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF6A1B9A)),
                  ),
                )
              : investimentos.isEmpty
                  ? _buildEmptyState()
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: _buildHeader(),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = investimentos[index];
                                return _buildAtivoCard(item);
                              },
                              childCount: investimentos.length,
                            ),
                          ),
                        ),
                        const SliverPadding(
                            padding: EdgeInsets.only(bottom: 140)),
                      ],
                    ),
          Positioned(
            right: 16,
            bottom: 115,
            child: SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF6A1B9A),
                elevation: 4,
                onPressed: _abrirDialogAdicionar,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6A1B9A),
                        Color(0xFF9C27B0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6A1B9A).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ],
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
            child: const Icon(
              Icons.trending_up,
              size: 64,
              color: Color(0xFF6A1B9A),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhum investimento',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E2F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para adicionar seu primeiro ativo',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    double valorTotal = investimentos.fold(0, (sum, item) {
      return sum +
          (item['preco_atual'] ?? item['preco_medio']) * item['quantidade'];
    });

    double rendimentoTotal = investimentos.fold(0, (sum, item) {
      final atual = item['preco_atual'] ?? item['preco_medio'];
      final medio = item['preco_medio'];
      return sum + ((atual - medio) * item['quantidade']);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PATRIMÔNIO TOTAL',
          style:
              TextStyle(fontSize: 12, color: Colors.white70, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Text(
          _formatarValor(valorTotal),
          style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rendimento',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  rendimentoTotal >= 0
                      ? '+${_formatarValor(rendimentoTotal)}'
                      : _formatarValor(rendimentoTotal),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: rendimentoTotal >= 0
                        ? Colors.green[200]
                        : Colors.red[200],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Ativos',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '${investimentos.length}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAtivoCard(Map<String, dynamic> item) {
    final cor = coresPorTipo[item['tipo']] ?? Colors.grey;
    final variacao = _calcularVariacao(
      item['preco_atual'] ?? item['preco_medio'],
      item['preco_medio'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item['tipo'] == 'FII'
                ? Icons.apartment
                : item['tipo'] == 'CRIPTO'
                    ? Icons.currency_bitcoin
                    : Icons.trending_up,
            color: cor,
            size: 24,
          ),
        ),
        title: Text(
          item['ticker'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['tipo'],
                    style: TextStyle(
                        fontSize: 10, color: cor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatarQuantidade(item['quantidade'])} cotas',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatarValor(item['preco_atual'] ?? item['preco_medio']),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: variacao >= 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${variacao >= 0 ? '+' : ''}${variacao.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 10,
                  color: variacao >= 0 ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetalhesAtivoScreen(ativo: item),
            ),
          ).then((_) => carregarInvestimentos());
        },
      ),
    );
  }

  Future<void> _abrirDialogAdicionar() async {
    final tickerController = TextEditingController();
    final quantidadeController = TextEditingController();
    final precoController = TextEditingController();
    String tipoSelecionado = 'ACAO';
    final totalController = TextEditingController();

    void calcularTotal() {
      try {
        double quantidade =
            double.parse(quantidadeController.text.replaceAll(',', '.'));
        double preco = double.parse(precoController.text.replaceAll(',', '.'));
        double totalInvestido = quantidade * preco;
        totalController.text =
            'R\$ ${totalInvestido.toStringAsFixed(2).replaceAll('.', ',')}';
      } catch (e) {
        totalController.text = 'R\$ 0,00';
      }
    }

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Adicionar Investimento',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tickerController,
                    decoration: InputDecoration(
                      labelText: 'Ticker',
                      hintText: 'Ex: PETR4, MXRF11, BTC',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.tag),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: tipoSelecionado,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Ativo',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ACAO', child: Text('📈 Ação')),
                      DropdownMenuItem(value: 'FII', child: Text('🏢 FII')),
                      DropdownMenuItem(value: 'ETF', child: Text('📊 ETF')),
                      DropdownMenuItem(value: 'BDR', child: Text('🌎 BDR')),
                      DropdownMenuItem(
                          value: 'CRIPTO', child: Text('🪙 Cripto')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => tipoSelecionado = value!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantidadeController,
                    decoration: InputDecoration(
                      labelText: 'Quantidade de Cotas',
                      hintText: 'Ex: 10',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      calcularTotal();
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: precoController,
                    decoration: InputDecoration(
                      labelText: 'Preço por Cota',
                      hintText: '5,00',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.attach_money),
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      calcularTotal();
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF6A1B9A).withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet,
                                size: 18, color: Color(0xFF6A1B9A)),
                            SizedBox(width: 8),
                            Text('Total Investido:',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Text(
                          totalController.text.isEmpty
                              ? 'R\$ 0,00'
                              : totalController.text,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A1B9A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if (tickerController.text.isEmpty ||
                      quantidadeController.text.isEmpty ||
                      precoController.text.isEmpty) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preencha todos os campos!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Fecha o dialog
                  Navigator.pop(context);

                  double quantidade = double.parse(
                      quantidadeController.text.replaceAll(',', '.'));
                  double preco =
                      double.parse(precoController.text.replaceAll(',', '.'));

                  // Salva no banco
                  await db.insertInvestimento({
                    'ticker': tickerController.text.toUpperCase(),
                    'tipo': tipoSelecionado,
                    'quantidade': quantidade,
                    'preco_medio': preco,
                    'preco_atual': preco,
                    'data_compra': DateTime.now().toIso8601String(),
                  });

                  // Recarrega a lista
                  await carregarInvestimentos();

                  // Notificação em background
                  NotificationService()
                      .addNotification(
                    titulo: '📈 Novo Investimento',
                    mensagem:
                        '${tickerController.text.toUpperCase()} - $quantidade cotas a R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}',
                    ticker: tickerController.text.toUpperCase(),
                    valor: preco,
                  )
                      .catchError((e) {
                    debugPrint('❌ Erro na notificação: $e');
                  });

                  // Feedback visual
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '✅ ${tickerController.text.toUpperCase()} adicionado!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Adicionar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

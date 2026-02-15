// lib/screens/analise_screen.dart
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';

class AnaliseScreen extends StatefulWidget {
  const AnaliseScreen({super.key});

  @override
  State<AnaliseScreen> createState() => _AnaliseScreenState();
}

class _AnaliseScreenState extends State<AnaliseScreen> {
  final DBHelper db = DBHelper();
  List<Map<String, dynamic>> investimentos = [];
  List<Map<String, dynamic>> proventos = [];
  bool carregando = true;

  // Filtros
  String periodoSelecionado = '1A';
  final List<String> periodos = ['6M', '1A', '2A', 'TODOS'];

  String ativoSelecionado = 'TODOS';
  List<String> ativosList = ['TODOS'];

  // Controle de categorias visíveis
  Map<String, bool> categoriasVisiveis = {
    'ACAO': true,
    'FII': true,
    'RENDA_FIXA': true,
    'CRIPTO': true,
    'BDR': true,
    'ETF': true,
    'OUTROS': true,
  };

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => carregando = true);

    investimentos = await db.getAllInvestimentos();

    // Mock proventos (depois implementar tabela real)
    proventos = _gerarMockProventos();

    // Atualiza lista de ativos para filtro
    for (var inv in investimentos) {
      if (!ativosList.contains(inv['ticker'])) {
        ativosList.add(inv['ticker']);
      }
    }

    setState(() => carregando = false);
  }

  List<Map<String, dynamic>> _gerarMockProventos() {
    return [
      {'data': '2025-02-15', 'valor': 150.0, 'ticker': 'BBAS3'},
      {'data': '2025-02-10', 'valor': 80.0, 'ticker': 'PETR4'},
      {'data': '2025-01-20', 'valor': 120.0, 'ticker': 'HGLG11'},
      {'data': '2025-01-05', 'valor': 90.0, 'ticker': 'KNRI11'},
    ];
  }

  // ========== CÁLCULOS ==========
  double get patrimonioTotal {
    return investimentos.fold(0, (sum, inv) {
      return sum +
          (inv['quantidade'] * (inv['preco_atual'] ?? inv['preco_medio']));
    });
  }

  double get valorInvestido {
    return investimentos.fold(0, (sum, inv) {
      return sum + (inv['quantidade'] * inv['preco_medio']);
    });
  }

  double get ganhoCapital => patrimonioTotal - valorInvestido;
  double get percentualGanho =>
      valorInvestido > 0 ? (ganhoCapital / valorInvestido) * 100 : 0;

  // ========== GRÁFICO PIZZA ==========
  List<Map<String, dynamic>> get dadosPizza {
    final Map<String, double> valores = {};

    for (var inv in investimentos) {
      final tipo = inv['tipo'] ?? 'OUTROS';
      if (!(categoriasVisiveis[tipo] ?? true)) continue;
      final valor =
          inv['quantidade'] * (inv['preco_atual'] ?? inv['preco_medio']);
      valores[tipo] = (valores[tipo] ?? 0) + valor;
    }

    return valores.entries.map((e) {
      return {
        'tipo': e.key,
        'valor': e.value,
        'percentual':
            patrimonioTotal > 0 ? (e.value / patrimonioTotal) * 100 : 0,
      };
    }).toList();
  }

  // ========== DADOS POR CATEGORIA ==========
  Map<String, List<Map<String, dynamic>>> get investimentosPorTipo {
    final Map<String, List<Map<String, dynamic>>> agrupado = {};

    for (var inv in investimentos) {
      final tipo = inv['tipo'] ?? 'OUTROS';
      if (!(categoriasVisiveis[tipo] ?? true)) continue;
      if (!agrupado.containsKey(tipo)) {
        agrupado[tipo] = [];
      }
      agrupado[tipo]!.add(inv);
    }

    return agrupado;
  }

  // ========== PROVENTOS ==========
  double get proventosUltimos12Meses {
    final hoje = DateTime.now();
    final umAnoAtras = DateTime(hoje.year - 1, hoje.month, hoje.day);

    return proventos.where((p) {
      final data = DateTime.parse(p['data']);
      return data.isAfter(umAnoAtras);
    }).fold(0, (sum, p) => sum + p['valor']);
  }

  double get proventosMesAtual {
    final hoje = DateTime.now();
    return proventos.where((p) {
      final data = DateTime.parse(p['data']);
      return data.month == hoje.month && data.year == hoje.year;
    }).fold(0, (sum, p) => sum + p['valor']);
  }

  // ========== BUILD ==========
  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Análise'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== CARDS RESUMO ==========
            Row(
              children: [
                Expanded(
                  child: _buildResumoCard(
                    'Patrimônio',
                    formatador.format(patrimonioTotal),
                    Icons.account_balance_wallet,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildResumoCard(
                    'Investido',
                    formatador.format(valorInvestido),
                    Icons.trending_down,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildResumoCard(
                    'Ganho',
                    '${formatador.format(ganhoCapital)} (${percentualGanho.toStringAsFixed(1)}%)',
                    Icons.trending_up,
                    ganhoCapital >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ========== GRÁFICOS ==========
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GRÁFICO PIZZA SIMULADO
                Expanded(
                  flex: 4,
                  child: _buildGraficoPizza(),
                ),
                const SizedBox(width: 12),
                // GRÁFICO EVOLUÇÃO
                Expanded(
                  flex: 6,
                  child: _buildGraficoEvolucao(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ========== ALOCAÇÃO POR ATIVO ==========
            _buildAlocacaoExpandivel(),

            const SizedBox(height: 20),

            // ========== PROVENTOS ==========
            _buildProventosCard(),
          ],
        ),
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
            color: Colors.black.withValues(alpha: 0.05),
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoPizza() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribuição',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...dadosPizza.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getCorPorTipo(item['tipo']),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getNomeTipo(item['tipo']),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    '${item['percentual'].toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGraficoEvolucao() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evolução Patrimonial',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...periodos.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(p),
                      selected: periodoSelecionado == p,
                      onSelected: (selected) {
                        setState(() {
                          periodoSelecionado = p;
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor:
                          const Color(0xFF6A1B9A).withValues(alpha: 0.2),
                      checkmarkColor: const Color(0xFF6A1B9A),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: periodoSelecionado == p
                            ? const Color(0xFF6A1B9A)
                            : Colors.black,
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButton<String>(
                    value: ativoSelecionado,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 16),
                    items: ativosList.map((ativo) {
                      return DropdownMenuItem(
                        value: ativo,
                        child:
                            Text(ativo, style: const TextStyle(fontSize: 11)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        ativoSelecionado = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Placeholder do gráfico
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [40, 60, 45, 70, 55, 80].map((valor) {
                return Container(
                  width: 20,
                  height: valor.toDouble(),
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A1B9A).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlocacaoExpandivel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alocação por Ativo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  if (value == 'gerenciar') {
                    _showGerenciarCategorias();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'gerenciar',
                    child: Text('Gerenciar categorias'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (investimentosPorTipo.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Nenhuma categoria visível',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
          else
            ...investimentosPorTipo.entries.map((entry) {
              return _buildCategoriaTile(entry.key, entry.value);
            }),
        ],
      ),
    );
  }

  Widget _buildCategoriaTile(
      String categoria, List<Map<String, dynamic>> ativos) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    double totalCategoria = ativos.fold(0, (sum, inv) {
      return sum +
          (inv['quantidade'] * (inv['preco_atual'] ?? inv['preco_medio']));
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _getNomeTipo(categoria),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                formatador.format(totalCategoria),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    categoriasVisiveis[categoria] = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12),
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            ...ativos.map((inv) => _buildAtivoTile(inv)),
          ],
        ),
      ),
    );
  }

  Widget _buildAtivoTile(Map<String, dynamic> inv) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final quantidade = inv['quantidade'];
    final precoMedio = inv['preco_medio'];
    final precoAtual = inv['preco_atual'] ?? precoMedio;
    final valorAtual = quantidade * precoAtual;
    final variacao = ((precoAtual - precoMedio) / precoMedio) * 100;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                inv['ticker'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                formatador.format(valorAtual),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Qnt: ${quantidade.toStringAsFixed(0)} | PM: R\$ ${precoMedio.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                'Atual: R\$ ${precoAtual.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: variacao >= 0 ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${variacao >= 0 ? '+' : ''}${variacao.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: variacao >= 0 ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProventosCard() {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6A1B9A).withValues(alpha: 0.1),
            Colors.white
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💰 Proventos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProventoItem(
                'Últimos 12 meses',
                formatador.format(proventosUltimos12Meses),
                Icons.calendar_today,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[300],
              ),
              _buildProventoItem(
                'Mês atual',
                formatador.format(proventosMesAtual),
                Icons.today,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProventoItem(String label, String valor, IconData icone) {
    return Column(
      children: [
        Icon(icone, color: const Color(0xFF6A1B9A), size: 20),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showGerenciarCategorias() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gerenciar Categorias',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...categoriasVisiveis.keys.map((categoria) {
                return CheckboxListTile(
                  title: Text(_getNomeTipo(categoria)),
                  value: categoriasVisiveis[categoria],
                  activeColor: const Color(0xFF6A1B9A),
                  onChanged: (value) {
                    setState(() {
                      categoriasVisiveis[categoria] = value!;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _getNomeTipo(String tipo) {
    switch (tipo) {
      case 'ACAO':
        return 'Ações';
      case 'FII':
        return 'FIIs';
      case 'RENDA_FIXA':
        return 'Renda Fixa';
      case 'CRIPTO':
        return 'Cripto';
      case 'BDR':
        return 'BDRs';
      case 'ETF':
        return 'ETFs';
      default:
        return tipo;
    }
  }

  Color _getCorPorTipo(String tipo) {
    switch (tipo) {
      case 'ACAO':
        return Colors.blue;
      case 'FII':
        return Colors.green;
      case 'RENDA_FIXA':
        return Colors.orange;
      case 'CRIPTO':
        return Colors.purple;
      case 'BDR':
        return Colors.teal;
      case 'ETF':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}

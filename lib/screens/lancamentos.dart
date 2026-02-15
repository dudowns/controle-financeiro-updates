import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';
import 'nova_transacao.dart';
import 'editar_transacao.dart';

class LancamentosScreen extends StatefulWidget {
  final VoidCallback? onLancamentoAdicionado;

  const LancamentosScreen({super.key, this.onLancamentoAdicionado});

  @override
  State<LancamentosScreen> createState() => _LancamentosScreenState();
}

class _LancamentosScreenState extends State<LancamentosScreen> {
  final DBHelper db = DBHelper();
  List<Map<String, dynamic>> lancamentos = [];
  bool carregando = true;

  // Filtros
  String filtroTipo = 'Todos';
  String filtroCategoria = 'Todas';
  DateTime? dataInicio;
  DateTime? dataFim;

  final List<String> tipos = ['Todos', 'Receita', 'Gasto'];
  final List<String> categorias = [
    'Todas',
    'Alimentação',
    'Transporte',
    'Moradia',
    'Saúde',
    'Educação',
    'Lazer',
    'Investimentos',
    'Outros'
  ];

  @override
  void initState() {
    super.initState();
    _carregarLancamentos();
  }

  Future<void> _carregarLancamentos() async {
    setState(() => carregando = true);
    lancamentos = await db.getAllLancamentos();
    setState(() => carregando = false);
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

  List<Map<String, dynamic>> get _lancamentosFiltrados {
    return lancamentos.where((l) {
      if (filtroTipo != 'Todos') {
        final tipoItem = l['tipo']?.toString().toLowerCase() ?? '';
        final tipoFiltro = filtroTipo.toLowerCase();

        if (tipoFiltro == 'receita' &&
            !(tipoItem == 'receita' || tipoItem == 'receitas')) {
          return false;
        }
        if (tipoFiltro == 'gasto' &&
            !(tipoItem == 'gasto' ||
                tipoItem == 'gastos' ||
                tipoItem == 'despesa')) {
          return false;
        }
      }

      if (filtroCategoria != 'Todas') {
        if (l['categoria'] != filtroCategoria) return false;
      }

      if (dataInicio != null) {
        try {
          final data = DateTime.parse(l['data']);
          if (data.isBefore(dataInicio!)) return false;
        } catch (_) {}
      }

      if (dataFim != null) {
        try {
          final data = DateTime.parse(l['data']);
          if (data.isAfter(dataFim!)) return false;
        } catch (_) {}
      }

      return true;
    }).toList();
  }

  double get _totalReceitas {
    return _lancamentosFiltrados.where((l) {
      final tipo = l['tipo']?.toString().toLowerCase();
      return tipo == 'receita' || tipo == 'receitas';
    }).fold(0, (sum, l) => sum + (l['valor'] ?? 0));
  }

  double get _totalDespesas {
    return _lancamentosFiltrados.where((l) {
      final tipo = l['tipo']?.toString().toLowerCase();
      return tipo == 'gasto' || tipo == 'gastos' || tipo == 'despesa';
    }).fold(0, (sum, l) => sum + (l['valor'] ?? 0));
  }

  double get _saldo => _totalReceitas - _totalDespesas;

  void _limparFiltros() {
    setState(() {
      filtroTipo = 'Todos';
      filtroCategoria = 'Todas';
      dataInicio = null;
      dataFim = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Lançamentos'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarLancamentos,
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Card de resumo
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Saldo',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatarValor(_saldo),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_lancamentosFiltrados.length} itens',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildResumoCard(
                              'Receitas',
                              _formatarValor(_totalReceitas),
                              Icons.arrow_upward,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildResumoCard(
                              'Despesas',
                              _formatarValor(_totalDespesas),
                              Icons.arrow_downward,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Lista de lançamentos
                Expanded(
                  child: lancamentos.isEmpty
                      ? _buildEmptyState()
                      : _lancamentosFiltrados.isEmpty
                          ? _buildSemResultados()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _lancamentosFiltrados.length,
                              itemBuilder: (context, index) {
                                final item = _lancamentosFiltrados[index];
                                return _buildLancamentoCard(item);
                              },
                            ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6A1B9A),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NovaTransacaoScreen(),
            ),
          );
          if (result == true) {
            await _carregarLancamentos();
            widget.onLancamentoAdicionado?.call();
          }
        },
      ),
    );
  }

  Widget _buildResumoCard(
      String titulo, String valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icone, size: 16, color: cor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                valor,
                style: TextStyle(
                  color: cor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLancamentoCard(Map<String, dynamic> item) {
    final tipoLower = item['tipo']?.toString().toLowerCase() ?? '';
    final isReceita = tipoLower == 'receita' || tipoLower == 'receitas';
    final cor = isReceita ? Colors.green : Colors.red;
    final icone = isReceita ? Icons.arrow_upward : Icons.arrow_downward;

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
          child: Icon(icone, color: cor, size: 24),
        ),
        title: Text(
          item['descricao'] ?? 'Sem descrição',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['categoria'] ?? 'Outros',
                    style: TextStyle(
                      fontSize: 10,
                      color: cor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatarData(item['data']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          _formatarValor(item['valor']?.toDouble() ?? 0),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: cor,
          ),
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditarTransacaoScreen(lancamento: item),
            ),
          );
          if (result == true) {
            await _carregarLancamentos();
            widget.onLancamentoAdicionado?.call();
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
            child: const Icon(
              Icons.receipt,
              size: 64,
              color: Color(0xFF6A1B9A),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhum lançamento',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E2F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para adicionar seu primeiro lançamento',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Nenhum resultado com os filtros atuais',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _limparFiltros,
            icon: const Icon(Icons.clear),
            label: const Text('Limpar filtros'),
          ),
        ],
      ),
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Tipo',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: tipos.map((tipo) {
                        return FilterChip(
                          label: Text(tipo),
                          selected: filtroTipo == tipo,
                          onSelected: (_) {
                            setStateModal(() {
                              filtroTipo = tipo;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Categoria',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: categorias.map((categoria) {
                        return FilterChip(
                          label: Text(categoria),
                          selected: filtroCategoria == categoria,
                          onSelected: (_) {
                            setStateModal(() {
                              filtroCategoria = categoria;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Período',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final data = await showDatePicker(
                                context: context,
                                initialDate: dataInicio ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (data != null) {
                                setStateModal(() {
                                  dataInicio = data;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[400]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      dataInicio == null
                                          ? 'Data inicial'
                                          : DateFormat('dd/MM/yyyy')
                                              .format(dataInicio!),
                                      style: TextStyle(
                                        color: dataInicio == null
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final data = await showDatePicker(
                                context: context,
                                initialDate: dataFim ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (data != null) {
                                setStateModal(() {
                                  dataFim = data;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[400]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      dataFim == null
                                          ? 'Data final'
                                          : DateFormat('dd/MM/yyyy')
                                              .format(dataFim!),
                                      style: TextStyle(
                                        color: dataFim == null
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _limparFiltros();
                              Navigator.pop(context);
                            },
                            child: const Text('Limpar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {});
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A1B9A),
                            ),
                            child: const Text('Aplicar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }
}

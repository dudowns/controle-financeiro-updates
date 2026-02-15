import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final DBHelper db = DBHelper();

  final Color roxoPrincipal = const Color(0xFF6A1B9A);
  final Color roxoClaro = const Color(0xFF8E24AA);
  final Color verdeLucro = const Color(0xFF2E7D32);
  final Color vermelhoPrejuizo = const Color(0xFFC62828);
  final Color fundoClaro = const Color(0xFFF5F5F7);

  double saldo = 0;
  double receitas = 0;
  double despesas = 0;
  bool carregando = true;

  // DADOS PARA GRÁFICO DE CATEGORIAS
  Map<String, double> gastosPorCategoria = {};

  // CORES PARA AS CATEGORIAS
  final Map<String, Color> coresCategorias = {
    'Alimentação': Colors.orange,
    'Lazer': Colors.purple,
    'Transporte': Colors.blue,
    'Saúde': Colors.red,
    'Educação': Colors.teal,
    'Moradia': Colors.brown,
    'Cartão de Crédito': Colors.redAccent,
    'Empréstimo': Colors.deepOrange,
    'Cuidados Pessoais': Colors.pink,
    'Investimentos': Colors.indigo,
    'Renda Extra': Colors.green,
    'Outros': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      carregarDados();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      carregarDados();
    });
  }

  // 🔥 FUNÇÃO PARA EXTRAIR VALOR DE FORMA SEGURA
  double _extrairValorSeguro(dynamic valorBruto) {
    if (valorBruto == null) return 0;
    
    if (valorBruto is double) {
      return valorBruto;
    } else if (valorBruto is int) {
      return valorBruto.toDouble();
    } else if (valorBruto is String) {
      // Remove espaços e substitui vírgula por ponto
      String valorStr = valorBruto.trim().replaceAll(',', '.');
      
      // Verifica se é um número válido
      final valor = double.tryParse(valorStr);
      if (valor != null && valor > 0) {
        return valor;
      }
      
      // Casos especiais de string inválida
      if (valorStr == '+' || valorStr == '-' || valorStr.isEmpty) {
        print('⚠️ Valor inválido ignorado: "$valorBruto"');
        return 0;
      }
    }
    
    print('⚠️ Tipo de valor não reconhecido: $valorBruto (${valorBruto.runtimeType})');
    return 0;
  }

  Future<void> carregarDados() async {
    if (!mounted) return;

    setState(() {
      carregando = true;
    });

    try {
      final dados = await db.getAllLancamentos();

      double totalReceitas = 0;
      double totalDespesas = 0;
      gastosPorCategoria.clear();

      for (var item in dados) {
        // 🔥 EXTRAI VALOR DE FORMA SEGURA
        final valor = _extrairValorSeguro(item["valor"]);
        
        // Ignora valores zerados (inválidos)
        if (valor <= 0) continue;

        if (item["tipo"] == "receita") {
          totalReceitas += valor;
        } else {
          totalDespesas += valor;

          String categoria = item["categoria"] ?? "Outros";
          gastosPorCategoria[categoria] =
              (gastosPorCategoria[categoria] ?? 0) + valor;
        }
      }

      if (mounted) {
        setState(() {
          receitas = totalReceitas;
          despesas = totalDespesas;
          saldo = totalReceitas - totalDespesas;
          carregando = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar dados: $e');
      if (mounted) {
        setState(() {
          carregando = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatarValor(double valor) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
    return formatter.format(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoClaro,
      body: SafeArea(
        child: carregando
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(roxoPrincipal),
                ),
              )
            : RefreshIndicator(
                onRefresh: carregarDados,
                color: roxoPrincipal,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Dashboard",
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      /// SALDO
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [roxoPrincipal, roxoClaro],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Saldo Total",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatarValor(saldo),
                              style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// GRÁFICOS LADO A LADO
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // GRÁFICO 1: RECEITAS X GASTOS
                          Expanded(
                            child: Container(
                              height: 250,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Se não houver dados, mostra mensagem
                                  if (receitas + despesas == 0)
                                    const Center(
                                      child: Text(
                                        'Nenhum lançamento',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  else
                                    PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 70,
                                        sections: [
                                          PieChartSectionData(
                                            value: receitas,
                                            color: verdeLucro,
                                            radius: 80,
                                            title: receitas + despesas == 0
                                                ? 'Receitas\n0%'
                                                : 'Receitas\n${((receitas / (receitas + despesas)) * 100).toStringAsFixed(0)}%',
                                            titleStyle: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                            titlePositionPercentageOffset: 0.5,
                                          ),
                                          PieChartSectionData(
                                            value: despesas,
                                            color: vermelhoPrejuizo,
                                            radius: 80,
                                            title: receitas + despesas == 0
                                                ? 'Gastos\n0%'
                                                : 'Gastos\n${((despesas / (receitas + despesas)) * 100).toStringAsFixed(0)}%',
                                            titleStyle: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                            titlePositionPercentageOffset: 0.5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Total",
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        _formatarValor(receitas + despesas),
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: roxoPrincipal),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          // GRÁFICO 2: GASTOS POR CATEGORIA
                          Expanded(
                            child: Container(
                              height: 250,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Se não houver gastos, mostra mensagem
                                  if (gastosPorCategoria.isEmpty)
                                    const Center(
                                      child: Text(
                                        'Nenhum gasto',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  else
                                    PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 70,
                                        sections: gastosPorCategoria.entries
                                            .map((entry) {
                                          final percentual = despesas > 0
                                              ? (entry.value / despesas) * 100
                                              : 0;
                                          return PieChartSectionData(
                                            value: entry.value,
                                            color: coresCategorias[entry.key] ??
                                                Colors.grey,
                                            radius: 80,
                                            title:
                                                '${entry.key}\n${percentual.toStringAsFixed(0)}%',
                                            titleStyle: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                            titlePositionPercentageOffset: 0.5,
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Gastos",
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        _formatarValor(despesas),
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: roxoPrincipal),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // BOTÃO PARA ATUALIZAR MANUALMENTE
                      Center(
                        child: TextButton.icon(
                          onPressed: carregarDados,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Atualizar dados'),
                          style: TextButton.styleFrom(
                            foregroundColor: roxoPrincipal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
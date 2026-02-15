import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';

class NovaMetaScreen extends StatefulWidget {
  const NovaMetaScreen({super.key});

  @override
  State<NovaMetaScreen> createState() => _NovaMetaScreenState();
}

class _NovaMetaScreenState extends State<NovaMetaScreen> {
  final DBHelper dbHelper = DBHelper();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();

  DateTime _dataInicio = DateTime.now();
  DateTime _dataFim = DateTime.now().add(const Duration(days: 30));

  String _corSelecionada = 'purple';
  String _iconeSelecionado = 'savings';

  final List<Map<String, dynamic>> _cores = [
    {'nome': 'purple', 'cor': const Color(0xFF6A1B9A), 'label': 'Roxo'},
    {'nome': 'blue', 'cor': const Color(0xFF2196F3), 'label': 'Azul'},
    {'nome': 'green', 'cor': const Color(0xFF4CAF50), 'label': 'Verde'},
    {'nome': 'orange', 'cor': const Color(0xFFFF9800), 'label': 'Laranja'},
    {'nome': 'red', 'cor': const Color(0xFFF44336), 'label': 'Vermelho'},
    {'nome': 'pink', 'cor': const Color(0xFFE91E63), 'label': 'Rosa'},
  ];

  final List<Map<String, dynamic>> _icones = [
    {'nome': 'savings', 'icone': Icons.savings, 'label': 'Economia'},
    {'nome': 'home', 'icone': Icons.home, 'label': 'Casa'},
    {'nome': 'car', 'icone': Icons.directions_car, 'label': 'Carro'},
    {'nome': 'travel', 'icone': Icons.flight, 'label': 'Viagem'},
    {'nome': 'education', 'icone': Icons.school, 'label': 'Estudo'},
    {'nome': 'health', 'icone': Icons.favorite, 'label': 'Saúde'},
    {'nome': 'gift', 'icone': Icons.card_giftcard, 'label': 'Presente'},
    {'nome': 'investment', 'icone': Icons.trending_up, 'label': 'Investimento'},
  ];

  // 🔥 MÉTODO DATA INÍCIO - SEM locale (FUNCIONA NO WINDOWS!)
  Future<void> _selecionarDataInicio() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      // SEM locale - funciona no Windows!
    );
    if (data != null) {
      setState(() {
        _dataInicio = data;
        if (_dataFim.isBefore(_dataInicio)) {
          _dataFim = _dataInicio.add(const Duration(days: 30));
        }
      });
    }
  }

  // 🔥 MÉTODO DATA FIM - SEM locale (FUNCIONA NO WINDOWS!)
  Future<void> _selecionarDataFim() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataFim,
      firstDate: _dataInicio,
      lastDate: DateTime(2030),
      // SEM locale - funciona no Windows!
    );
    if (data != null) {
      setState(() {
        _dataFim = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Meta'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Campo Título
                    TextField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título da Meta',
                        hintText: 'Ex: Comprar um carro',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFF6A1B9A), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo Descrição
                    TextField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Ex: Economizar para entrada do carro',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFF6A1B9A), width: 2),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Campo Valor
                    TextField(
                      controller: _valorController,
                      decoration: const InputDecoration(
                        labelText: 'Valor Objetivo',
                        prefixText: 'R\$ ',
                        hintText: '0,00',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFF6A1B9A), width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // 🔥 DATAS - FUNCIONANDO NO WINDOWS!
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selecionarDataInicio,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[400]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Data Início',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy')
                                        .format(_dataInicio),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _selecionarDataFim,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[400]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Data Fim',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(_dataFim),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Seleção de Cor
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Cor da Meta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cores.length,
                        itemBuilder: (context, index) {
                          final cor = _cores[index];
                          final isSelected = _corSelecionada == cor['nome'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _corSelecionada = cor['nome'];
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: cor['cor'],
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      )
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: cor['cor'].withOpacity(0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Seleção de Ícone
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ícone da Meta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _icones.length,
                        itemBuilder: (context, index) {
                          final icone = _icones[index];
                          final isSelected = _iconeSelecionado == icone['nome'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _iconeSelecionado = icone['nome'];
                              });
                            },
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF6A1B9A).withOpacity(0.1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(
                                        color: const Color(0xFF6A1B9A),
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    icone['icone'],
                                    color: isSelected
                                        ? const Color(0xFF6A1B9A)
                                        : Colors.grey[600],
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    icone['label'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected
                                          ? const Color(0xFF6A1B9A)
                                          : Colors.grey[600],
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botão Salvar
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF6A1B9A)),
                      ),
                    );
                  },
                );
                Future.delayed(const Duration(milliseconds: 800), () {
                  _salvarMeta();
                });
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: const Text(
                'CRIAR META',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _salvarMeta() async {
    if (_tituloController.text.isEmpty || _valorController.text.isEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Preencha título e valor!'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      double valor = double.parse(_valorController.text.replaceAll(',', '.'));

      await dbHelper.insertMeta({
        'titulo': _tituloController.text,
        'descricao': _descricaoController.text,
        'valor_objetivo': valor,
        'valor_atual': 0,
        'data_inicio': _dataInicio.toIso8601String(),
        'data_fim': _dataFim.toIso8601String(),
        'cor': _corSelecionada,
        'icone': _iconeSelecionado,
        'concluida': 0,
      });

      Navigator.pop(context);
      Navigator.pop(context, true);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }
}

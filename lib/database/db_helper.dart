import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final appDir = await getApplicationSupportDirectory();
    final path = join(appDir.path, 'financeiro.db');

    debugPrint('📁 Banco de dados em: $path');

    return await openDatabase(
      path,
      version: 8, // 🔥 VERSÃO 8!
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('🔨 Criando tabelas versão $version');

    await db.execute('''
      CREATE TABLE lancamentos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valor REAL,
        descricao TEXT,
        tipo TEXT,
        categoria TEXT,
        data TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE metas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT,
        descricao TEXT,
        valor_objetivo REAL,
        valor_atual REAL,
        data_inicio TEXT,
        data_fim TEXT,
        cor TEXT,
        icone TEXT,
        concluida INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE investimentos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticker TEXT NOT NULL,
        tipo TEXT NOT NULL,
        quantidade REAL NOT NULL,
        preco_medio REAL NOT NULL,
        preco_atual REAL,
        data_compra TEXT,
        corretora TEXT,
        setor TEXT,
        dividend_yield REAL,
        ultima_atualizacao TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE proventos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticker TEXT NOT NULL,
        tipo_provento TEXT,
        valor_por_cota REAL NOT NULL,
        quantidade REAL DEFAULT 1,  // 🔥 COLUNA ADICIONADA!
        data_pagamento TEXT NOT NULL,
        data_com TEXT,
        total_recebido REAL,
        sync_automatico INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE depositos_meta(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meta_id INTEGER NOT NULL,
        valor REAL NOT NULL,
        data_deposito TEXT NOT NULL,
        observacao TEXT,
        FOREIGN KEY (meta_id) REFERENCES metas(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE renda_fixa(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        tipo_renda TEXT NOT NULL,
        valor REAL NOT NULL,
        taxa REAL NOT NULL,
        data_aplicacao TEXT NOT NULL,
        data_vencimento TEXT NOT NULL,
        dias INTEGER NOT NULL,
        rendimento_bruto REAL,
        iof REAL,
        ir REAL,
        rendimento_liquido REAL,
        valor_final REAL,
        indexador TEXT,
        liquidez TEXT DEFAULT 'Diária',
        is_lci INTEGER DEFAULT 0,
        status TEXT DEFAULT 'ativo'
      )
    ''');

    debugPrint('✅ Tabelas criadas com sucesso!');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Atualizando banco: $oldVersion -> $newVersion');

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS metas(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          titulo TEXT,
          descricao TEXT,
          valor_objetivo REAL,
          valor_atual REAL,
          data_inicio TEXT,
          data_fim TEXT,
          cor TEXT,
          icone TEXT,
          concluida INTEGER DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS investimentos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ticker TEXT NOT NULL,
          tipo TEXT NOT NULL,
          quantidade REAL NOT NULL,
          preco_medio REAL NOT NULL,
          preco_atual REAL,
          data_compra TEXT,
          corretora TEXT,
          setor TEXT,
          dividend_yield REAL,
          ultima_atualizacao TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS proventos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ticker TEXT NOT NULL,
          tipo_provento TEXT,
          valor_por_cota REAL NOT NULL,
          data_pagamento TEXT NOT NULL,
          data_com TEXT,
          total_recebido REAL,
          sync_automatico INTEGER DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS depositos_meta(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          meta_id INTEGER NOT NULL,
          valor REAL NOT NULL,
          data_deposito TEXT NOT NULL,
          observacao TEXT,
          FOREIGN KEY (meta_id) REFERENCES metas(id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS renda_fixa(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          tipo_renda TEXT NOT NULL,
          valor REAL NOT NULL,
          taxa REAL NOT NULL,
          data_aplicacao TEXT NOT NULL,
          data_vencimento TEXT NOT NULL,
          dias INTEGER NOT NULL,
          rendimento_bruto REAL,
          iof REAL,
          ir REAL,
          rendimento_liquido REAL,
          valor_final REAL,
          indexador TEXT,
          is_lci INTEGER DEFAULT 0,
          status TEXT DEFAULT 'ativo'
        )
      ''');
    }

    if (oldVersion < 6) {}

    if (oldVersion < 7) {
      debugPrint('📦 Versão 7: Adicionando coluna liquidez');
      try {
        await db.execute('ALTER TABLE renda_fixa ADD COLUMN liquidez TEXT DEFAULT "Diária"');
      } catch (e) {}
    }

    if (oldVersion < 8) {
      debugPrint('📦 Versão 8: Adicionando coluna quantidade na tabela proventos');
      try {
        await db.execute('ALTER TABLE proventos ADD COLUMN quantidade REAL DEFAULT 1');
        debugPrint('✅ Coluna quantidade adicionada com sucesso!');
      } catch (e) {
        debugPrint('⚠️ Erro ao adicionar coluna quantidade: $e');
      }
    }
  }

  // ============ MÉTODOS DE LANÇAMENTOS ============
  Future<int> insertLancamento(Map<String, dynamic> lancamento) async {
    final db = await database;
    return await db.insert('lancamentos', lancamento);
  }

  Future<List<Map<String, dynamic>>> getAllLancamentos() async {
    final db = await database;
    return await db.query('lancamentos', orderBy: 'data DESC');
  }

  Future<int> deleteLancamento(int id) async {
    final db = await database;
    return await db.delete('lancamentos', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getLancamentoById(int id) async {
    final db = await database;
    final results = await db.query('lancamentos', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateLancamento(Map<String, dynamic> lancamento) async {
    final db = await database;
    return await db.update('lancamentos', lancamento, where: 'id = ?', whereArgs: [lancamento['id']]);
  }

  // ============ MÉTODOS DE METAS ============
  Future<int> insertMeta(Map<String, dynamic> meta) async {
    final db = await database;
    return await db.insert('metas', meta);
  }

  Future<List<Map<String, dynamic>>> getAllMetas() async {
    final db = await database;
    return await db.query('metas', orderBy: 'concluida ASC, data_fim ASC');
  }

  Future<Map<String, dynamic>?> getMetaById(int id) async {
    final db = await database;
    final results = await db.query('metas', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateMeta(Map<String, dynamic> meta) async {
    final db = await database;
    return await db.update('metas', meta, where: 'id = ?', whereArgs: [meta['id']]);
  }

  Future<int> deleteMeta(int id) async {
    final db = await database;
    return await db.delete('metas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> atualizarProgressoMeta(int id, double valorAtual) async {
    final db = await database;
    return await db.update('metas', {'valor_atual': valorAtual}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> concluirMeta(int id) async {
    final db = await database;
    return await db.update('metas', {'concluida': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ============ MÉTODOS DE DEPÓSITOS DE METAS ============
  Future<int> insertDepositoMeta(Map<String, dynamic> deposito) async {
    final db = await database;
    return await db.insert('depositos_meta', deposito);
  }

  Future<List<Map<String, dynamic>>> getDepositosByMetaId(int metaId) async {
    final db = await database;
    return await db.query('depositos_meta', where: 'meta_id = ?', whereArgs: [metaId], orderBy: 'data_deposito DESC');
  }

  Future<double> getTotalDepositosByMetaId(int metaId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(valor) as total FROM depositos_meta WHERE meta_id = ?', [metaId]);
    return result.first['total'] as double? ?? 0.0;
  }

  Future<int> deleteDeposito(int id) async {
    final db = await database;
    return await db.delete('depositos_meta', where: 'id = ?', whereArgs: [id]);
  }

  // ============ MÉTODOS DE INVESTIMENTOS ============
  Future<int> insertInvestimento(Map<String, dynamic> investimento) async {
    final db = await database;
    return await db.insert('investimentos', {
      ...investimento,
      'ultima_atualizacao': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllInvestimentos() async {
    final db = await database;
    return await db.query('investimentos', orderBy: 'ticker ASC');
  }

  Future<Map<String, dynamic>?> getInvestimentoById(int id) async {
    final db = await database;
    final results = await db.query('investimentos', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateInvestimento(Map<String, dynamic> investimento) async {
    final db = await database;
    return await db.update('investimentos', {
      ...investimento,
      'ultima_atualizacao': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [investimento['id']]);
  }

  Future<int> deleteInvestimento(int id) async {
    final db = await database;
    return await db.delete('investimentos', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updatePrecoAtual(int id, double preco) async {
    final db = await database;
    return await db.update('investimentos', {
      'preco_atual': preco,
      'ultima_atualizacao': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  // ============ MÉTODOS DE PROVENTOS ============
  Future<int> insertProvento(Map<String, dynamic> provento) async {
    final db = await database;
    debugPrint('💾 Inserindo provento: $provento');
    return await db.insert('proventos', provento);
  }

  Future<List<Map<String, dynamic>>> getAllProventos() async {
    final db = await database;
    return await db.query('proventos', orderBy: 'data_pagamento DESC');
  }

  Future<int> updateProvento(Map<String, dynamic> provento) async {
    final db = await database;
    return await db.update(
      'proventos',
      provento,
      where: 'id = ?',
      whereArgs: [provento['id']],
    );
  }

  Future<int> deleteProvento(int id) async {
    final db = await database;
    return await db.delete(
      'proventos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getProventosFuturos() async {
    final db = await database;
    return await db.query('proventos', where: 'data_pagamento > ?', whereArgs: [DateTime.now().toIso8601String()], orderBy: 'data_pagamento ASC');
  }

  Future<double> getTotalProventosMes() async {
    final db = await database;
    final agora = DateTime.now();
    final primeiroDia = DateTime(agora.year, agora.month, 1).toIso8601String();
    final ultimoDia = DateTime(agora.year, agora.month + 1, 0).toIso8601String();
    final results = await db.query('proventos', where: 'data_pagamento BETWEEN ? AND ?', whereArgs: [primeiroDia, ultimoDia]);
    return results.fold<double>(0, (sum, item) => sum + ((item['total_recebido'] as num?)?.toDouble() ?? 0));
  }

  Future<List<Map<String, dynamic>>> getProventosPorMes(int mes, int ano) async {
    final db = await database;
    final primeiroDia = DateTime(ano, mes, 1).toIso8601String();
    final ultimoDia = DateTime(ano, mes + 1, 0).toIso8601String();
    return await db.query('proventos', where: 'data_pagamento BETWEEN ? AND ?', whereArgs: [primeiroDia, ultimoDia], orderBy: 'data_pagamento ASC');
  }

  Future<List<Map<String, dynamic>>> getProventosPorAno(int ano) async {
    final db = await database;
    final primeiroDia = DateTime(ano, 1, 1).toIso8601String();
    final ultimoDia = DateTime(ano, 12, 31).toIso8601String();
    return await db.query('proventos', where: 'data_pagamento BETWEEN ? AND ?', whereArgs: [primeiroDia, ultimoDia], orderBy: 'data_pagamento ASC');
  }

  Future<List<Map<String, dynamic>>> getProventosAgrupadosPorTicker() async {
    final db = await database;
    return await db.rawQuery('SELECT ticker, SUM(total_recebido) as total, COUNT(*) as quantidade, AVG(valor_por_cota) as media_cota FROM proventos GROUP BY ticker ORDER BY total DESC');
  }

  Future<List<Map<String, dynamic>>> getProventosPorTipo(String tipo) async {
    final db = await database;
    final investimentosDoTipo = await db.query('investimentos', where: 'tipo = ?', whereArgs: [tipo]);
    List<String> tickers = investimentosDoTipo.map((e) => e['ticker'] as String).toList();
    if (tickers.isEmpty) return [];
    final placeholders = List.filled(tickers.length, '?').join(',');
    return await db.query('proventos', where: 'ticker IN ($placeholders)', whereArgs: tickers, orderBy: 'data_pagamento DESC');
  }

  Future<Map<String, dynamic>?> getUltimoProvento(String ticker) async {
    final db = await database;
    final resultados = await db.query('proventos', where: 'ticker = ?', whereArgs: [ticker], orderBy: 'data_pagamento DESC', limit: 1);
    return resultados.isNotEmpty ? resultados.first : null;
  }

  // ============ MÉTODOS DE RENDA FIXA ============
  Future<int> insertRendaFixa(Map<String, dynamic> renda) async {
    final db = await database;
    return await db.insert('renda_fixa', renda);
  }

  Future<List<Map<String, dynamic>>> getAllRendaFixa() async {
    final db = await database;
    return await db.query('renda_fixa', orderBy: 'data_aplicacao DESC');
  }

  Future<Map<String, dynamic>?> getRendaFixaById(int id) async {
    final db = await database;
    final results = await db.query('renda_fixa', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateRendaFixa(Map<String, dynamic> renda) async {
    final db = await database;
    return await db.update('renda_fixa', renda, where: 'id = ?', whereArgs: [renda['id']]);
  }

  Future<int> deleteRendaFixa(int id) async {
    final db = await database;
    return await db.delete('renda_fixa', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getRendaFixaVencendoProximo() async {
    final db = await database;
    final hoje = DateTime.now().toIso8601String();
    final proximoMes = DateTime.now().add(const Duration(days: 30)).toIso8601String();
    return await db.query('renda_fixa', where: 'data_vencimento BETWEEN ? AND ? AND status = ?', whereArgs: [hoje, proximoMes, 'ativo'], orderBy: 'data_vencimento ASC');
  }

  // ============ FUNÇÕES DE CÁLCULO PARA RENDA FIXA ============
  
  double calcularRendimentoDiario(double valor, double percentualCDI) {
    double taxaCDIAnual = 14.65;
    double cdiDiario = pow(1 + (taxaCDIAnual / 100), 1/252) - 1;
    double rendimentoDiario = valor * cdiDiario * (percentualCDI / 100);
    return rendimentoDiario;
  }

  int _calcularDiasUteis(DateTime inicio, DateTime fim) {
    int diasUteis = 0;
    DateTime atual = inicio;
    while (atual.isBefore(fim) || atual.isAtSameMomentAs(fim)) {
      if (atual.weekday != DateTime.saturday && atual.weekday != DateTime.sunday) {
        diasUteis++;
      }
      atual = atual.add(const Duration(days: 1));
    }
    return diasUteis;
  }

  DateTime _proximoDiaUtil(DateTime inicio, int dias) {
    DateTime data = inicio.add(Duration(days: dias));
    while (data.weekday == DateTime.saturday || data.weekday == DateTime.sunday) {
      data = data.add(const Duration(days: 1));
    }
    return data;
  }

  List<Map<String, dynamic>> calcularEvolucaoDiaria(Map<String, dynamic> item) {
    List<Map<String, dynamic>> evolucao = [];
    try {
      DateTime dataAplicacao = DateTime.parse(item['data_aplicacao']);
      DateTime dataVencimento = DateTime.parse(item['data_vencimento']);
      double valorInicial = item['valor'];
      double percentualCDI = item['taxa'];
      DateTime hoje = DateTime.now();
      int diasUteisTotal = _calcularDiasUteis(dataAplicacao, dataVencimento);
      double valorAtual = valorInicial;
      
      for (int i = 1; i <= diasUteisTotal; i++) {
        DateTime data = _proximoDiaUtil(dataAplicacao, i);
        if (data.isAfter(hoje)) break;
        double rendimentoHoje = calcularRendimentoDiario(valorAtual, percentualCDI);
        valorAtual += rendimentoHoje;
        if (i % 7 == 0 || i == diasUteisTotal) {
          evolucao.add({
            'data': data.toIso8601String(),
            'valor': valorAtual,
            'rendimento': rendimentoHoje,
            'rendimentoAcumulado': valorAtual - valorInicial,
            'dia': i,
          });
        }
      }
      
      int diasUteisAteHoje = _calcularDiasUteis(dataAplicacao, hoje);
      double valorHoje = valorInicial;
      for (int i = 1; i <= diasUteisAteHoje; i++) {
        double rendimento = calcularRendimentoDiario(valorHoje, percentualCDI);
        valorHoje += rendimento;
      }
      
      evolucao.add({
        'data': hoje.toIso8601String(),
        'valor': valorHoje,
        'rendimento': 0,
        'rendimentoAcumulado': valorHoje - valorInicial,
        'dia': diasUteisAteHoje,
        'hoje': true,
      });
      
      evolucao.sort((a, b) => a['data'].compareTo(b['data']));
    } catch (e) {
      debugPrint('Erro ao calcular evolução diária: $e');
    }
    return evolucao;
  }

  double calcularValorEmData(Map<String, dynamic> item, DateTime data) {
    try {
      DateTime dataAplicacao = DateTime.parse(item['data_aplicacao']);
      double valorInicial = item['valor'];
      double percentualCDI = item['taxa'];
      if (data.isBefore(dataAplicacao)) return valorInicial;
      int diasUteis = _calcularDiasUteis(dataAplicacao, data);
      double valorAtual = valorInicial;
      for (int i = 1; i <= diasUteis; i++) {
        double rendimentoHoje = calcularRendimentoDiario(valorAtual, percentualCDI);
        valorAtual += rendimentoHoje;
      }
      return valorAtual;
    } catch (e) {
      return item['valor'] ?? 0;
    }
  }

  double calcularIR(int diasInvestido, double rendimento) {
    if (diasInvestido <= 180) return rendimento * 0.225;
    else if (diasInvestido <= 360) return rendimento * 0.20;
    else if (diasInvestido <= 720) return rendimento * 0.175;
    else return rendimento * 0.15;
  }

  double calcularIOF(int diasInvestido, double rendimento) {
    if (diasInvestido < 30) {
      double aliquota = (30 - diasInvestido) / 30 * 0.96;
      return rendimento * aliquota;
    }
    return 0;
  }

  Map<String, double> simularRendaFixa({
    required double valor,
    required double taxa,
    required int dias,
    required String tipo,
    bool isLCI = false,
  }) {
    double rendimentoBruto = valor * (taxa / 100) * (dias / 365);
    double iof = 0;
    double ir = 0;

    if (!isLCI) {
      iof = calcularIOF(dias, rendimentoBruto);
      ir = calcularIR(dias, rendimentoBruto - iof);
    }

    double rendimentoLiquido = rendimentoBruto - iof - ir;
    double valorFinal = valor + rendimentoLiquido;

    return {
      'rendimentoBruto': rendimentoBruto,
      'iof': iof,
      'ir': ir,
      'rendimentoLiquido': rendimentoLiquido,
      'valorFinal': valorFinal,
    };
  }
}
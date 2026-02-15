import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final List<Map<String, dynamic>> _notificacoes = [];
  VoidCallback? _onUpdate;

  List<Map<String, dynamic>> get notificacoes => _notificacoes;
  int get naoLidas => _notificacoes.where((n) => n['lida'] == false).length;

  void registerUpdateCallback(VoidCallback callback) {
    _onUpdate = callback;
  }

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) async {
        debugPrint('Notificação clicada: ${details.payload}');
      },
    );

    tz.initializeTimeZones();
  }

  Future<void> addNotification({
    required String titulo,
    required String mensagem,
    String? ticker,
    double? valor,
  }) async {
    final novaNotif = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'titulo': titulo,
      'mensagem': mensagem,
      'data': DateTime.now(),
      'lida': false,
      'ticker': ticker,
      'valor': valor,
    };

    _notificacoes.insert(0, novaNotif);
    _onUpdate?.call();

    await _showPushNotification(titulo, mensagem);
  }

  Future<void> _showPushNotification(String titulo, String mensagem) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'app_notifications',
      'Notificações do App',
      channelDescription: 'Notificações do sistema',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF6A1B9A),
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch,
      titulo,
      mensagem,
      details,
    );
  }

  Future<void> scheduleProventoNotification({
    required String ticker,
    required DateTime dataPagamento,
    required double valor,
    int id = 1,
  }) async {
    final hoje = DateTime.now();

    if (dataPagamento.isBefore(hoje)) return;

    if (Platform.isWindows) {
      debugPrint(
          '📌 Windows: Criando lembrete para $ticker em ${dataPagamento.toString()}');

      await addNotification(
        titulo: '📅 Lembrete: $ticker',
        mensagem:
            'Provento agendado para ${dataPagamento.day}/${dataPagamento.month}/${dataPagamento.year} - R\$ ${valor.toStringAsFixed(2)}',
        ticker: ticker,
        valor: valor,
      );

      debugPrint('✅ Lembrete criado na lista de notificações');
      return;
    }

    try {
      final scheduledDate = DateTime(
        dataPagamento.year,
        dataPagamento.month,
        dataPagamento.day,
        8,
        0,
        0,
      );

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'proventos_channel',
        'Proventos',
        channelDescription: 'Notificações de proventos',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF6A1B9A),
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        '💰 $ticker pagou provento!',
        'Valor: R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')} por cota',
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('✅ Notificação agendada para $ticker em $scheduledDate');
    } catch (e) {
      debugPrint('❌ Erro ao agendar notificação: $e');

      await addNotification(
        titulo: '📅 Lembrete: $ticker',
        mensagem:
            'Provento agendado para ${dataPagamento.day}/${dataPagamento.month}/${dataPagamento.year}',
        ticker: ticker,
        valor: valor,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!Platform.isWindows) {
      await _notificationsPlugin.cancel(id);
    }
  }

  void marcarComoLida(int id) {
    final index = _notificacoes.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notificacoes[index]['lida'] = true;
      _onUpdate?.call();
    }
  }

  void marcarTodasComoLidas() {
    for (var n in _notificacoes) {
      n['lida'] = true;
    }
    _onUpdate?.call();
  }

  void limparTodas() {
    _notificacoes.clear();
    _onUpdate?.call();
  }

  Future<void> cancelAll() async {
    if (!Platform.isWindows) {
      await _notificationsPlugin.cancelAll();
    }
  }

  Future<void> showTestNotification() async {
    await addNotification(
      titulo: '🔔 Teste de Notificação',
      mensagem: 'Se você está vendo isso, as notificações funcionam!',
    );
  }
}

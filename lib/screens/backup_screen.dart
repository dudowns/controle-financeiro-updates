import 'dart:io'; // 🔥 ESSENCIAL PARA USAR File!
import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import 'package:intl/intl.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  List<File> backups = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarBackups();
  }

  Future<void> _carregarBackups() async {
    setState(() => carregando = true);
    backups = await _backupService.listarBackups();
    setState(() => carregando = false);
  }

  String _formatarData(File file) {
    final stat = file.statSync();
    return DateFormat('dd/MM/yyyy HH:mm').format(stat.modified);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup e Restauração'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarBackups,
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final sucesso = await _backupService.fazerBackup();
                      if (sucesso && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Backup realizado com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _carregarBackups();
                      }
                    },
                    icon: const Icon(Icons.backup),
                    label: const Text('FAZER BACKUP AGORA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
                Expanded(
                  child: backups.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_off,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum backup encontrado',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Clique em "FAZER BACKUP AGORA" para começar',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: backups.length,
                          itemBuilder: (context, index) {
                            final backup = backups[index];
                            final nome = backup.path.split('\\').last;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.backup,
                                    color: Color(0xFF6A1B9A)),
                                title: Text(nome),
                                subtitle: Text(_formatarData(backup)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.restore,
                                          color: Colors.green),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title:
                                                const Text('Restaurar Backup'),
                                            content: Text(
                                                'Deseja restaurar o backup $nome? O banco de dados atual será substituído.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  Navigator.pop(context);
                                                  final sucesso =
                                                      await _backupService
                                                          .restaurarBackup(
                                                              backup.path);
                                                  if (sucesso &&
                                                      context.mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            '✅ Backup restaurado! Reinicie o app.'),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                ),
                                                child: const Text('Restaurar'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Excluir Backup'),
                                            content: Text(
                                                'Deseja excluir o backup $nome?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await backup.delete();
                                                  if (context.mounted) {
                                                    Navigator.pop(context);
                                                    _carregarBackups();
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            '🗑️ Backup excluído'),
                                                        backgroundColor:
                                                            Colors.orange,
                                                      ),
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: const Text('Excluir'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
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
    );
  }
}

import 'package:desktop_updater/desktop_updater.dart';

class DesktopUpdaterController {
  final Uri appArchiveUrl;
  final DesktopUpdateLocalization? localization;
  DesktopUpdaterController({required this.appArchiveUrl, this.localization});
}

class UpdaterService {
  static final UpdaterService _instance = UpdaterService._internal();
  factory UpdaterService() => _instance;
  UpdaterService._internal();

  late DesktopUpdaterController _controller;

  // 🔥 URL do arquivo JSON (depois você sobe no GitHub)
  final String _jsonUrl =
      'https://raw.githubusercontent.com/dudowns/controle-financeiro-updates/refs/heads/main/app-archive.json';

  void init() {
    _controller = DesktopUpdaterController(
      appArchiveUrl: Uri.parse(_jsonUrl),
      localization: const DesktopUpdateLocalization(
        updateAvailableText: "Atualização disponível",
        newVersionAvailableText: "Versão {} {} disponível",
        newVersionLongText:
            "Nova versão disponível para download. Clique abaixo para baixar. Isso vai baixar {} MB de dados.",
        restartText: "Reiniciar para atualizar",
        warningTitleText: "Tem certeza?",
        restartWarningText:
            "É necessário reiniciar para completar a instalação.\nDeseja reiniciar agora?",
        warningCancelText: "Agora não",
        warningConfirmText: "Reiniciar",
      ),
    );
  }

  DesktopUpdaterController get controller => _controller;
}

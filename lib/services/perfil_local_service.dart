import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O FirebaseAuth só aceita uma URL http para `photoURL` — não um arquivo
/// local. Como não temos Firebase Storage configurado neste projeto, a
/// foto escolhida na galeria é copiada para a pasta de documentos do
/// próprio app e o caminho é guardado localmente, indexado pelo uid do
/// usuário logado (assim cada conta usada no aparelho tem sua própria
/// foto, mesmo sem sincronizar entre dispositivos).
class PerfilLocalService {
  String _chave(String uid) => 'foto_local_$uid';

  Future<String?> obterCaminhoFoto(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final caminho = prefs.getString(_chave(uid));
    if (caminho == null) return null;

    // Se o arquivo foi apagado por fora do app, não retorna um caminho
    // morto para a tela tentar carregar.
    return File(caminho).existsSync() ? caminho : null;
  }

  /// Copia a imagem escolhida para um local permanente dentro do app e
  /// guarda o caminho associado ao usuário.
  Future<String> salvarFoto(String uid, File imagemOriginal) async {
    final diretorio = await getApplicationDocumentsDirectory();
    final extensao = imagemOriginal.path.split('.').last;
    final destino = File('${diretorio.path}/perfil_$uid.$extensao');

    await imagemOriginal.copy(destino.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave(uid), destino.path);
    return destino.path;
  }

  Future<void> removerFoto(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final caminho = prefs.getString(_chave(uid));
    if (caminho != null) {
      final arquivo = File(caminho);
      if (arquivo.existsSync()) await arquivo.delete();
    }
    await prefs.remove(_chave(uid));
  }
}

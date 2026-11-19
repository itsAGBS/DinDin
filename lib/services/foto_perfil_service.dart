import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda a foto de perfil no armazenamento do aparelho, separada por usuário.
///
/// Salvamos só o NOME do arquivo (não o caminho completo), porque o diretório
/// de documentos pode mudar entre atualizações do app, principalmente no iOS.
class FotoPerfilService {
  FotoPerfilService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  String _chave(String uid) => 'foto_perfil_$uid';

  Future<File?> _arquivo(String nome) async {
    final pasta = await getApplicationDocumentsDirectory();
    final arquivo = File('${pasta.path}/$nome');
    return await arquivo.exists() ? arquivo : null;
  }

  /// Caminho da foto salva para [uid], ou null se não houver.
  Future<String?> carregar(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString(_chave(uid));
    if (nome == null) return null;
    return (await _arquivo(nome))?.path;
  }

  /// Abre câmera/galeria e salva a escolha. Retorna o novo caminho, ou null se
  /// a pessoa cancelou.
  Future<String?> escolher(String uid, ImageSource origem) async {
    final escolhida = await _picker.pickImage(
      source: origem,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (escolhida == null) return null;

    final pasta = await getApplicationDocumentsDirectory();
    // Nome novo a cada troca: evita o Flutter reaproveitar a imagem antiga
    // que ficou em cache para o mesmo caminho.
    final nome = 'foto_perfil_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destino = File('${pasta.path}/$nome');
    await File(escolhida.path).copy(destino.path);

    final prefs = await SharedPreferences.getInstance();
    final anterior = prefs.getString(_chave(uid));
    await prefs.setString(_chave(uid), nome);
    await _apagarArquivo(anterior);

    return destino.path;
  }

  Future<void> remover(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString(_chave(uid));
    await prefs.remove(_chave(uid));
    await _apagarArquivo(nome);
  }

  Future<void> _apagarArquivo(String? nome) async {
    if (nome == null) return;
    try {
      final arquivo = await _arquivo(nome);
      await arquivo?.delete();
    } catch (_) {
      // Sobrar um arquivo antigo no disco não é grave.
    }
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../services/foto_perfil_service.dart';

/// Foto de perfil do usuário logado (guardada localmente no aparelho).
class FotoPerfilProvider extends ChangeNotifier {
  FotoPerfilProvider({FotoPerfilService? service, FirebaseAuth? firebaseAuth})
      : _service = service ?? FotoPerfilService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    _authSubscription = _firebaseAuth.authStateChanges().listen(_aoMudarUsuario);
  }

  final FotoPerfilService _service;
  final FirebaseAuth _firebaseAuth;
  late final StreamSubscription<User?> _authSubscription;

  String? _uid;
  String? _caminho;
  bool _processando = false;

  /// Caminho do arquivo da foto, ou null se o usuário não escolheu nenhuma.
  String? get caminho => _caminho;
  bool get temFoto => _caminho != null;
  bool get processando => _processando;

  Future<void> _aoMudarUsuario(User? user) async {
    _uid = user?.uid;
    _caminho = null;
    notifyListeners();

    final uid = _uid;
    if (uid == null) return;

    final caminho = await _service.carregar(uid);
    // O usuário pode ter trocado de conta enquanto a leitura rodava.
    if (_uid != uid) return;
    _caminho = caminho;
    notifyListeners();
  }

  /// Retorna false só se algo deu errado (cancelar não é erro).
  Future<bool> escolher(ImageSource origem) async {
    final uid = _uid;
    if (uid == null) return false;

    _processando = true;
    notifyListeners();
    try {
      final novoCaminho = await _service.escolher(uid, origem);
      if (novoCaminho != null && _uid == uid) _caminho = novoCaminho;
      return true;
    } catch (_) {
      return false;
    } finally {
      _processando = false;
      notifyListeners();
    }
  }

  Future<bool> remover() async {
    final uid = _uid;
    if (uid == null) return false;

    _processando = true;
    notifyListeners();
    try {
      await _service.remover(uid);
      if (_uid == uid) _caminho = null;
      return true;
    } catch (_) {
      return false;
    } finally {
      _processando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}

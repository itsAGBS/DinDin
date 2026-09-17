import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

enum AuthStatus { carregando, autenticado, naoAutenticado }

/// Expõe o estado de autenticação (usuário logado, carregando, erro) para
/// as telas via [Provider], escondendo os detalhes do Firebase.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      _user = user;
      _status =
          user != null ? AuthStatus.autenticado : AuthStatus.naoAutenticado;
      notifyListeners();
    });
  }

  final AuthService _authService;
  late final StreamSubscription<User?> _authSubscription;

  User? _user;
  AuthStatus _status = AuthStatus.carregando;
  bool _processando = false;
  String? _erro;

  User? get user => _user;
  AuthStatus get status => _status;
  bool get processando => _processando;
  String? get erro => _erro;
  bool get estaLogado => _status == AuthStatus.autenticado;

  Future<bool> cadastrar({
    required String email,
    required String senha,
    String? nome,
  }) {
    return _executar(() => _authService.cadastrarComEmail(
          email: email,
          senha: senha,
          nome: nome,
        ));
  }

  Future<bool> entrar({required String email, required String senha}) {
    return _executar(
      () => _authService.entrarComEmail(email: email, senha: senha),
    );
  }

  Future<bool> entrarComGoogle() {
    return _executar(() => _authService.entrarComGoogle());
  }

  Future<bool> redefinirSenha(String email) async {
    return _executar(() => _authService.enviarEmailRedefinicaoSenha(email));
  }

  Future<void> sair() async {
    await _authService.sair();
  }

  /// Roda uma operação assíncrona de auth, cuidando de estado de
  /// carregamento e captura de erro de forma padronizada.
  Future<bool> _executar(Future<void> Function() acao) async {
    _processando = true;
    _erro = null;
    notifyListeners();

    try {
      await acao();
      _processando = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _processando = false;
      _erro = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _processando = false;
      _erro = 'Algo deu errado. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  void limparErro() {
    _erro = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}

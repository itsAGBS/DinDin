import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/perfil_local_service.dart';

enum AuthStatus { carregando, autenticado, naoAutenticado }

/// Expõe o estado de autenticação (usuário logado, carregando, erro) para
/// as telas via [Provider], escondendo os detalhes do Firebase.
///
/// Também expõe operações de perfil (nome, foto local, troca de senha)
/// usadas pela tela de configurações do usuário.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService, PerfilLocalService? perfilService})
      : _authService = authService ?? AuthService(),
        _perfilService = perfilService ?? PerfilLocalService() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      _user = user;
      _status =
          user != null ? AuthStatus.autenticado : AuthStatus.naoAutenticado;
      notifyListeners();
      _carregarFotoLocal();
    });
  }

  final AuthService _authService;
  final PerfilLocalService _perfilService;

  User? _user;
  AuthStatus _status = AuthStatus.carregando;
  bool _processando = false;
  String? _erro;
  String? _fotoLocalPath;

  User? get user => _user;
  AuthStatus get status => _status;
  bool get processando => _processando;
  String? get erro => _erro;
  bool get estaLogado => _status == AuthStatus.autenticado;

  /// Caminho local (no aparelho) da foto de perfil escolhida na galeria,
  /// se houver.
  String? get fotoLocalPath => _fotoLocalPath;

  /// Contas via Google não têm senha própria no DinDin, então a opção de
  /// "alterar senha" só faz sentido para contas de e-mail/senha.
  bool get temSenha =>
      _user?.providerData.any((p) => p.providerId == 'password') ?? false;

  Future<void> _carregarFotoLocal() async {
    final uid = _user?.uid;
    _fotoLocalPath = uid == null ? null : await _perfilService.obterCaminhoFoto(uid);
    notifyListeners();
  }

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

  /// Atualiza o nome exibido no perfil.
  Future<bool> atualizarNome(String nome) {
    return _executar(() async {
      await _authService.atualizarNome(nome);
      _user = _authService.currentUser;
    });
  }

  /// Troca a senha da conta (só válido para contas de e-mail/senha, veja
  /// [temSenha]).
  Future<bool> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) {
    return _executar(() => _authService.alterarSenha(
          senhaAtual: senhaAtual,
          novaSenha: novaSenha,
        ));
  }

  /// Copia a foto escolhida na galeria para um local permanente e a
  /// associa ao usuário logado.
  Future<bool> atualizarFoto(File imagem) {
    return _executar(() async {
      final uid = _user?.uid;
      if (uid == null) throw AuthException('Nenhum usuário logado.');
      _fotoLocalPath = await _perfilService.salvarFoto(uid, imagem);
    });
  }

  Future<bool> removerFoto() {
    return _executar(() async {
      final uid = _user?.uid;
      if (uid == null) throw AuthException('Nenhum usuário logado.');
      await _perfilService.removerFoto(uid);
      _fotoLocalPath = null;
    });
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

  late final StreamSubscription<User?> _authSubscription;
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Encapsula toda a comunicação com o Firebase Authentication.
///
/// Mantém a UI (telas) e o resto do app desacoplados dos detalhes do
/// FirebaseAuth/GoogleSignIn. Qualquer erro do Firebase é traduzido para
/// uma mensagem em português através de [AuthException].
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Stream que emite o usuário atual sempre que o estado de login muda
  /// (login, logout, expiração de sessão, etc).
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Usuário logado no momento (ou null se não houver ninguém logado).
  User? get currentUser => _firebaseAuth.currentUser;

  /// Cria uma conta nova com e-mail e senha.
  Future<User?> cadastrarComEmail({
    required String email,
    required String senha,
    String? nome,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );

      if (nome != null && nome.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(nome.trim());
        await credential.user?.reload();
      }

      return _firebaseAuth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mensagemDeErro(e.code));
    }
  }

  /// Faz login com e-mail e senha.
  Future<User?> entrarComEmail({
    required String email,
    required String senha,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mensagemDeErro(e.code));
    }
  }

  /// Faz login (ou cadastro automático, caso seja a primeira vez) com Google.
  Future<User?> entrarComGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      // Usuário cancelou o fluxo de login do Google.
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mensagemDeErro(e.code));
    }
  }

  /// Envia e-mail de redefinição de senha.
  Future<void> enviarEmailRedefinicaoSenha(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mensagemDeErro(e.code));
    }
  }

  /// Faz logout de qualquer provedor (e-mail/senha ou Google).
  Future<void> sair() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Traduz os códigos de erro do FirebaseAuth para mensagens em português,
  /// amigáveis para exibir na tela de login/cadastro.
  String _mensagemDeErro(String code) {
    switch (code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
        return 'Não existe conta com este e-mail.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Já existe uma conta com este e-mail.';
      case 'weak-password':
        return 'A senha precisa ter pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Falha de conexão. Verifique sua internet.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      default:
        return 'Não foi possível completar a operação. Tente novamente.';
    }
  }
}

/// Exceção de autenticação com mensagem já traduzida para o usuário final.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// biometria (via `local_auth`) e PIN numérico.

class BloqueioService {
  BloqueioService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _storage = secureStorage ?? const FlutterSecureStorage();

  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _storage;

  static const _chaveBloqueioAtivado = 'bloqueio_ativado';
  static const _chaveBiometriaAtivada = 'bloqueio_biometria_ativada';
  static const _chavePinHash = 'bloqueio_pin_hash';
  static const _chavePinSalt = 'bloqueio_pin_salt';


  // Biometria

  /// Verifica se o aparelho tem hardware de biometria e se há alguma biometria (digital, rosto etc.) cadastrada no aparelho.
  
  Future<bool> biometriaDisponivel() async {
    try {
      final suportado = await _localAuth.isDeviceSupported();
      final podeChecar = await _localAuth.canCheckBiometrics;
      return suportado && podeChecar;
    } catch (_) {
      return false;
    }
  }

  /// Abre o prompt nativo de biometria do sistema (digital/rosto).
 
  Future<bool> autenticarComBiometria() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Autentique-se para acessar o DinDin',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // Configuração de bloqueio (ativo/inativo)

  Future<bool> bloqueioEstaAtivado() async {
    return (await _storage.read(key: _chaveBloqueioAtivado)) == 'true';
  }

  Future<void> definirBloqueioAtivado(bool ativado) async {
    await _storage.write(
      key: _chaveBloqueioAtivado,
      value: ativado.toString(),
    );
  }

  Future<bool> biometriaEstaAtivada() async {
    return (await _storage.read(key: _chaveBiometriaAtivada)) == 'true';
  }

  Future<void> definirBiometriaAtivada(bool ativada) async {
    await _storage.write(
      key: _chaveBiometriaAtivada,
      value: ativada.toString(),
    );
  }

  // PIN numérico

  Future<bool> pinConfigurado() async {
    return (await _storage.read(key: _chavePinHash)) != null;
  }

  /// Cria (ou substitui) o PIN do usuário.
  
  Future<void> configurarPin(String pin) async {
    final salt = _gerarSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _chavePinSalt, value: salt);
    await _storage.write(key: _chavePinHash, value: hash);
  }

  Future<bool> verificarPin(String pin) async {
    final salt = await _storage.read(key: _chavePinSalt);
    final hashSalvo = await _storage.read(key: _chavePinHash);
    if (salt == null || hashSalvo == null) return false;
    return _hashPin(pin, salt) == hashSalvo;
  }

  Future<void> removerPin() async {
    await _storage.delete(key: _chavePinHash);
    await _storage.delete(key: _chavePinSalt);
  }

  /// Remove toda a configuração de bloqueio (usado ao desativar a proteção por completo nas configurações).
  
  Future<void> limparConfiguracao() async {
    await Future.wait([
      _storage.delete(key: _chaveBloqueioAtivado),
      _storage.delete(key: _chaveBiometriaAtivada),
      removerPin(),
    ]);
  }

  String _gerarSalt() {
    final aleatorio = Random.secure();
    final bytes = List<int>.generate(16, (_) => aleatorio.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final digest = sha256.convert(utf8.encode('$pin:$salt'));
    return digest.toString();
  }
}

import 'package:flutter/widgets.dart';

import '../services/bloqueio_service.dart';

/// Estado da proteção de acesso ao app.
enum StatusBloqueio {
  /// Ainda carregando as preferências salvas no dispositivo.
  carregando,

  /// Bloqueio desligado nas configurações — app abre direto no dashboard.
  desativado,

  /// Bloqueio ligado e aguardando o usuário se autenticar.
  bloqueado,

  /// Bloqueio ligado e usuário já autenticado nesta sessão do app.
  desbloqueado,
}


class BloqueioProvider extends ChangeNotifier with WidgetsBindingObserver {
  BloqueioProvider({BloqueioService? service})
      : _service = service ?? BloqueioService() {
    WidgetsBinding.instance.addObserver(this);
    _inicializar();
  }

  final BloqueioService _service;

  StatusBloqueio _status = StatusBloqueio.carregando;
  bool _biometriaDisponivelNoAparelho = false;
  bool _biometriaAtivada = false;
  bool _pinConfigurado = false;
  bool _processando = false;
  String? _erro;

  StatusBloqueio get status => _status;
  bool get bloqueioAtivado => _status != StatusBloqueio.desativado;
  bool get biometriaDisponivelNoAparelho => _biometriaDisponivelNoAparelho;
  bool get biometriaAtivada => _biometriaAtivada;
  bool get pinConfigurado => _pinConfigurado;
  bool get processando => _processando;
  String? get erro => _erro;

  Future<void> _inicializar() async {
    _biometriaDisponivelNoAparelho = await _service.biometriaDisponivel();
    _biometriaAtivada = await _service.biometriaEstaAtivada();
    _pinConfigurado = await _service.pinConfigurado();
    final ativado = await _service.bloqueioEstaAtivado();

    _status = ativado ? StatusBloqueio.bloqueado : StatusBloqueio.desativado;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!bloqueioAtivado) return;

    // Assim que o app vai para segundo plano, exige autenticação de novo na próxima vez em que for exibido.
    
    final foiParaSegundoPlano = state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden;

    if (foiParaSegundoPlano && _status == StatusBloqueio.desbloqueado) {
      _status = StatusBloqueio.bloqueado;
      notifyListeners();
    }
  }

  Future<bool> desbloquearComBiometria() async {
    _processando = true;
    _erro = null;
    notifyListeners();

    final sucesso = await _service.autenticarComBiometria();

    _processando = false;
    if (sucesso) _status = StatusBloqueio.desbloqueado;
    notifyListeners();
    return sucesso;
  }

  Future<bool> desbloquearComPin(String pin) async {
    _processando = true;
    _erro = null;
    notifyListeners();

    final correto = await _service.verificarPin(pin);

    _processando = false;
    if (correto) {
      _status = StatusBloqueio.desbloqueado;
    } else {
      _erro = 'PIN incorreto. Tente novamente.';
    }
    notifyListeners();
    return correto;
  }

  /// Ativa a proteção do app definindo um PIN novo. A biometria pode ser ligada depois, separadamente, se o aparelho suportar.
  
  Future<void> ativarComPin(String pin) async {
    await _service.configurarPin(pin);
    await _service.definirBloqueioAtivado(true);
    _pinConfigurado = true;
    _status = StatusBloqueio.desbloqueado;
    notifyListeners();
  }

  Future<void> alterarPin(String novoPin) async {
    await _service.configurarPin(novoPin);
    _pinConfigurado = true;
    notifyListeners();
  }

  Future<void> definirBiometriaAtivada(bool ativada) async {
    await _service.definirBiometriaAtivada(ativada);
    _biometriaAtivada = ativada;
    notifyListeners();
  }

  Future<void> desativarBloqueio() async {
    await _service.limparConfiguracao();
    _biometriaAtivada = false;
    _pinConfigurado = false;
    _status = StatusBloqueio.desativado;
    notifyListeners();
  }

  void limparErro() {
    _erro = null;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

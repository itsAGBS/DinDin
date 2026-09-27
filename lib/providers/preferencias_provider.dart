import 'package:flutter/material.dart';

import '../models/moeda.dart';
import '../services/preferencias_service.dart';

/// Expõe as preferências gerais do app (tema, moeda, resumo mensal
/// automático) para qualquer tela via Provider, escondendo os detalhes
/// de `shared_preferences`.
class PreferenciasProvider extends ChangeNotifier {
  PreferenciasProvider({PreferenciasService? service})
      : _service = service ?? PreferenciasService() {
    _carregar();
  }

  final PreferenciasService _service;

  bool _carregando = true;
  bool _modoEscuro = false;
  Moeda _moeda = Moeda.brl;
  bool _resumoMensalAutomatico = false;

  bool get carregando => _carregando;
  bool get modoEscuro => _modoEscuro;
  Moeda get moeda => _moeda;
  bool get resumoMensalAutomatico => _resumoMensalAutomatico;

  /// Pronto para ser passado direto em `MaterialApp(themeMode: ...)`.
  ThemeMode get themeMode => _modoEscuro ? ThemeMode.dark : ThemeMode.light;

  Future<void> _carregar() async {
    _modoEscuro = await _service.obterModoEscuro();
    _moeda = await _service.obterMoeda();
    _resumoMensalAutomatico = await _service.obterResumoMensalAutomatico();
    _carregando = false;
    notifyListeners();
  }

  Future<void> definirModoEscuro(bool ativado) async {
    _modoEscuro = ativado;
    notifyListeners();
    await _service.salvarModoEscuro(ativado);
  }

  Future<void> definirMoeda(Moeda moeda) async {
    _moeda = moeda;
    notifyListeners();
    await _service.salvarMoeda(moeda);
  }

  /// Liga/desliga o resumo mensal automático. Esta tela só guarda a
  /// preferência; a geração do resumo em si (notificação, e-mail, etc.)
  /// é uma funcionalidade separada, ainda não implementada.
  Future<void> definirResumoMensalAutomatico(bool ativado) async {
    _resumoMensalAutomatico = ativado;
    notifyListeners();
    await _service.salvarResumoMensalAutomatico(ativado);
  }
}

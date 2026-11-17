import 'package:flutter/material.dart';

import '../services/preferencias_service.dart';
import '../utils/moeda.dart';

/// Preferências do app: tema, moeda e resumo mensal automático.
///
/// Carregue com [PreferenciasProvider.carregar] antes do `runApp` para que o
/// tema salvo já seja aplicado no primeiro frame (sem "piscar" o tema errado).
class PreferenciasProvider extends ChangeNotifier {
  PreferenciasProvider(this._service)
      : _themeMode = _service.lerTema(),
        _moeda = _service.lerMoeda(),
        _resumoMensalAtivo = _service.lerResumoAtivo(),
        _ultimoResumo = _service.lerUltimoResumo();

  static Future<PreferenciasProvider> carregar() async {
    return PreferenciasProvider(await PreferenciasService.criar());
  }

  final PreferenciasService _service;

  ThemeMode _themeMode;
  Moeda _moeda;
  bool _resumoMensalAtivo;
  String? _ultimoResumo;

  ThemeMode get themeMode => _themeMode;
  Moeda get moeda => _moeda;
  bool get resumoMensalAtivo => _resumoMensalAtivo;

  String formatarMoeda(double valor) => _moeda.formatar(valor);

  Future<void> definirTema(ThemeMode tema) async {
    if (tema == _themeMode) return;
    _themeMode = tema;
    notifyListeners();
    await _service.salvarTema(tema);
  }

  Future<void> definirMoeda(Moeda moeda) async {
    if (moeda == _moeda) return;
    _moeda = moeda;
    notifyListeners();
    await _service.salvarMoeda(moeda);
  }

  Future<void> definirResumoMensal(bool ativo) async {
    if (ativo == _resumoMensalAtivo) return;
    _resumoMensalAtivo = ativo;

    if (ativo) {
      // Ao ativar no meio do mês, o primeiro resumo só aparece quando o mês
      // virar (e será o do mês que acabou de fechar).
      _ultimoResumo = chaveDoMes(DateTime.now());
      await _service.salvarUltimoResumo(_ultimoResumo!);
    }

    notifyListeners();
    await _service.salvarResumoAtivo(ativo);
  }

  /// True quando o resumo está ligado e ainda não foi exibido neste mês.
  bool deveExibirResumo(DateTime agora) {
    if (!_resumoMensalAtivo) return false;
    final ultimo = _ultimoResumo;
    if (ultimo == null) return false;
    return ultimo != chaveDoMes(agora);
  }

  Future<void> marcarResumoExibido(DateTime agora) async {
    _ultimoResumo = chaveDoMes(agora);
    await _service.salvarUltimoResumo(_ultimoResumo!);
  }

  static String chaveDoMes(DateTime data) =>
      '${data.year}-${data.month.toString().padLeft(2, '0')}';
}

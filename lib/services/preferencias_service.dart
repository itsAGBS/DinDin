import 'package:shared_preferences/shared_preferences.dart';

import '../models/moeda.dart';

/// Guarda as preferências gerais do app (não ligadas a uma conta
/// específica) no armazenamento local do dispositivo via
/// `shared_preferences`. Segue o mesmo papel que `BloqueioService` tem
/// para o bloqueio: quem fala com a biblioteca externa é só esta classe.
class PreferenciasService {
  static const _chaveModoEscuro = 'pref_modo_escuro';
  static const _chaveMoeda = 'pref_moeda';
  static const _chaveResumoMensal = 'pref_resumo_mensal_automatico';

  Future<bool> obterModoEscuro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chaveModoEscuro) ?? false;
  }

  Future<void> salvarModoEscuro(bool ativado) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveModoEscuro, ativado);
  }

  Future<Moeda> obterMoeda() async {
    final prefs = await SharedPreferences.getInstance();
    return MoedaExtensao.porCodigo(prefs.getString(_chaveMoeda));
  }

  Future<void> salvarMoeda(Moeda moeda) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveMoeda, moeda.codigo);
  }

  Future<bool> obterResumoMensalAutomatico() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chaveResumoMensal) ?? false;
  }

  Future<void> salvarResumoMensalAutomatico(bool ativado) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveResumoMensal, ativado);
  }
}

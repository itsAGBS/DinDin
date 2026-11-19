import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/moeda.dart';

/// Persistência local das preferências do app (tema, moeda, resumo mensal).
class PreferenciasService {
  PreferenciasService(this._prefs);

  final SharedPreferences _prefs;

  static Future<PreferenciasService> criar() async {
    return PreferenciasService(await SharedPreferences.getInstance());
  }

  static const _chaveTema = 'pref_tema';
  static const _chaveMoeda = 'pref_moeda';
  static const _chaveResumoAtivo = 'pref_resumo_mensal_ativo';
  static const _chaveUltimoResumo = 'pref_resumo_mensal_ultimo_mes';

  ThemeMode lerTema() {
    switch (_prefs.getString(_chaveTema)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> salvarTema(ThemeMode tema) async {
    await _prefs.setString(_chaveTema, tema.name);
  }

  Moeda lerMoeda() => Moeda.doNome(_prefs.getString(_chaveMoeda));

  Future<void> salvarMoeda(Moeda moeda) async {
    await _prefs.setString(_chaveMoeda, moeda.name);
  }

  bool lerResumoAtivo() => _prefs.getBool(_chaveResumoAtivo) ?? false;

  Future<void> salvarResumoAtivo(bool ativo) async {
    await _prefs.setBool(_chaveResumoAtivo, ativo);
  }

  /// Mês (formato "2026-11") em que o resumo foi exibido pela última vez.
  String? lerUltimoResumo() => _prefs.getString(_chaveUltimoResumo);

  Future<void> salvarUltimoResumo(String mes) async {
    await _prefs.setString(_chaveUltimoResumo, mes);
  }
}

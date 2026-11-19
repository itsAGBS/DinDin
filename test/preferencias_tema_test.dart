import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:din_din/providers/preferencias_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tema padrão segue o sistema', () async {
    final prefs = await PreferenciasProvider.carregar();
    expect(prefs.themeMode, ThemeMode.system);
  });

  test('definirTema altera o modo e notifica os ouvintes', () async {
    final prefs = await PreferenciasProvider.carregar();
    var notificacoes = 0;
    prefs.addListener(() => notificacoes++);

    await prefs.definirTema(ThemeMode.dark);

    expect(prefs.themeMode, ThemeMode.dark);
    expect(notificacoes, 1);
  });

  test('tema escolhido é persistido e restaurado', () async {
    final prefs = await PreferenciasProvider.carregar();
    await prefs.definirTema(ThemeMode.dark);

    final recarregado = await PreferenciasProvider.carregar();
    expect(recarregado.themeMode, ThemeMode.dark);
  });
}

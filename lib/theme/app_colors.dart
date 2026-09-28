import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color receita = Color(0xFF22C55E);
  static const Color despesa = Color(0xFFEF4444);
  static const Color destaque = Color(0xFF172033);
  static const Color acao = Color(0xFF2563EB);
  static const Color alerta = Color(0xFFF59E0B);
  static const Color fundo = Color(0xFFF8FAFC);
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color fundo;
  final Color cardFundo;
  final Color textoPrincipal;
  final Color textoSecundario;
  final Color borda;
  final Color receita;
  final Color despesa;
  final Color azul;
  final Color alerta;
  final Color saldoDestaqueFundo;
  final Color? saldoDestaqueBorda;
  final Color sombra;
  final Color overlaySutil;

  const AppPalette({
    required this.fundo,
    required this.cardFundo,
    required this.textoPrincipal,
    required this.textoSecundario,
    required this.borda,
    required this.receita,
    required this.despesa,
    required this.azul,
    required this.alerta,
    required this.saldoDestaqueFundo,
    this.saldoDestaqueBorda,
    required this.sombra,
    required this.overlaySutil,
  });

  static const AppPalette claro = AppPalette(
    fundo: Color(0xFFF8FAFC),
    cardFundo: Color(0xFFFFFFFF),
    textoPrincipal: Color(0xFF172033),
    textoSecundario: Color(0xFF94A3B8),
    borda: Color(0xFFE5E9F0),
    receita: Color(0xFF22C55E),
    despesa: Color(0xFFEF4444),
    azul: Color(0xFF2563EB),
    alerta: Color(0xFFF59E0B),
    saldoDestaqueFundo: Color(0xFF172033),
    sombra: Color(0x0F000000),
    overlaySutil: Color(0x0A172033),
  );

  static const AppPalette escuro = AppPalette(
    fundo: Color(0xFF0F172A),
    cardFundo: Color(0xFF1E293B),
    textoPrincipal: Color(0xFFF1F5F9),
    textoSecundario: Color(0xFF94A3B8),
    borda: Color(0xFF334155),
    receita: Color(0xFF4ADE80),
    despesa: Color(0xFFF87171),
    azul: Color(0xFF60A5FA),
    alerta: Color(0xFFFBBF24),
    saldoDestaqueFundo: Color(0xFF1E293B),
    saldoDestaqueBorda: Color(0xFF334155),
    sombra: Color(0x59000000),
    overlaySutil: Color(0x14FFFFFF),
  );

  Color corDoSaldo(double saldo) {
    if (saldo < 0) return despesa;
    if (saldo > 0) return receita;
    return saldoDestaqueFundo;
  }

  @override
  AppPalette copyWith({
    Color? fundo,
    Color? cardFundo,
    Color? textoPrincipal,
    Color? textoSecundario,
    Color? borda,
    Color? receita,
    Color? despesa,
    Color? azul,
    Color? alerta,
    Color? saldoDestaqueFundo,
    Color? saldoDestaqueBorda,
    Color? sombra,
    Color? overlaySutil,
  }) {
    return AppPalette(
      fundo: fundo ?? this.fundo,
      cardFundo: cardFundo ?? this.cardFundo,
      textoPrincipal: textoPrincipal ?? this.textoPrincipal,
      textoSecundario: textoSecundario ?? this.textoSecundario,
      borda: borda ?? this.borda,
      receita: receita ?? this.receita,
      despesa: despesa ?? this.despesa,
      azul: azul ?? this.azul,
      alerta: alerta ?? this.alerta,
      saldoDestaqueFundo: saldoDestaqueFundo ?? this.saldoDestaqueFundo,
      saldoDestaqueBorda: saldoDestaqueBorda ?? this.saldoDestaqueBorda,
      sombra: sombra ?? this.sombra,
      overlaySutil: overlaySutil ?? this.overlaySutil,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      fundo: Color.lerp(fundo, other.fundo, t)!,
      cardFundo: Color.lerp(cardFundo, other.cardFundo, t)!,
      textoPrincipal: Color.lerp(textoPrincipal, other.textoPrincipal, t)!,
      textoSecundario: Color.lerp(textoSecundario, other.textoSecundario, t)!,
      borda: Color.lerp(borda, other.borda, t)!,
      receita: Color.lerp(receita, other.receita, t)!,
      despesa: Color.lerp(despesa, other.despesa, t)!,
      azul: Color.lerp(azul, other.azul, t)!,
      alerta: Color.lerp(alerta, other.alerta, t)!,
      saldoDestaqueFundo: Color.lerp(saldoDestaqueFundo, other.saldoDestaqueFundo, t)!,
      saldoDestaqueBorda: Color.lerp(saldoDestaqueBorda, other.saldoDestaqueBorda, t),
      sombra: Color.lerp(sombra, other.sombra, t)!,
      overlaySutil: Color.lerp(overlaySutil, other.overlaySutil, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get cores =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.claro;
}

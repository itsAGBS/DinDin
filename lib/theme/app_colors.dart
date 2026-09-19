import 'package:flutter/material.dart';

/// Paleta oficial do DinDin, já definida pelo grupo.
/// Mantida centralizada aqui para não espalhar hex code pelas telas.
class AppColors {
  AppColors._();

  static const Color receita = Color(0xFF22C55E); // verde
  static const Color despesa = Color(0xFFEF4444); // vermelho
  static const Color destaque = Color(0xFF172033); // navy (cards de destaque)
  static const Color acao = Color(0xFF2563EB); // azul (ações/links)
  static const Color alerta = Color(0xFFF59E0B); // âmbar (categorias/alertas)
  static const Color fundo = Color(0xFFF8FAFC); // fundo claro

  /// Cor do saldo com base no valor:
  /// negativo -> vermelho, positivo -> verde, zerado -> navy neutro.
  static Color corDoSaldo(double saldo) {
    if (saldo < 0) return despesa;
    if (saldo > 0) return receita;
    return destaque;
  }
}

/// Moedas que o usuário pode escolher para exibir os valores no app.
///
/// Guardamos só a preferência aqui (o valor numérico das transações não
/// muda). Se no futuro o app exibir conversão de valores de verdade, essa
/// é a extensão natural para colocar a taxa de câmbio.
enum Moeda { brl, usd, eur }

extension MoedaExtensao on Moeda {
  /// Código ISO 4217, útil se algum dia integrarmos uma API de câmbio.
  String get codigo {
    switch (this) {
      case Moeda.brl:
        return 'BRL';
      case Moeda.usd:
        return 'USD';
      case Moeda.eur:
        return 'EUR';
    }
  }

  String get simbolo {
    switch (this) {
      case Moeda.brl:
        return r'R$';
      case Moeda.usd:
        return r'US$';
      case Moeda.eur:
        return '€';
    }
  }

  String get rotulo {
    switch (this) {
      case Moeda.brl:
        return 'Real (R\$)';
      case Moeda.usd:
        return 'Dólar (US\$)';
      case Moeda.eur:
        return 'Euro (€)';
    }
  }

  /// Formata um valor no padrão dessa moeda, ex: "R\$ 1.234,56".
  String formatar(double valor) {
    final absoluto = valor.abs().toStringAsFixed(2).replaceAll('.', ',');
    final sinal = valor < 0 ? '-' : '';
    return '$sinal$simbolo $absoluto';
  }

  static Moeda porCodigo(String? codigo) {
    return Moeda.values.firstWhere(
      (m) => m.codigo == codigo,
      orElse: () => Moeda.brl,
    );
  }
}

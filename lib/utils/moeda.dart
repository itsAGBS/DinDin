import 'package:intl/intl.dart';

/// Moedas disponíveis para exibição no app.
///
/// Atenção: trocar a moeda altera apenas o símbolo e o formato mostrados.
/// Os valores guardados no banco NÃO são convertidos.
enum Moeda {
  real(
    codigo: 'BRL',
    simbolo: r'R$',
    locale: 'pt_BR',
    nome: 'Real brasileiro',
  ),
  dolar(
    codigo: 'USD',
    simbolo: r'US$',
    locale: 'en_US',
    nome: 'Dólar americano',
  ),
  euro(
    codigo: 'EUR',
    simbolo: '€',
    locale: 'de_DE',
    nome: 'Euro',
  );

  const Moeda({
    required this.codigo,
    required this.simbolo,
    required this.locale,
    required this.nome,
  });

  final String codigo;
  final String simbolo;
  final String locale;
  final String nome;

  /// Ex.: 1234.5 -> "R$ 1.234,50" (real) ou "US$1,234.50" (dólar).
  String formatar(double valor) {
    return NumberFormat.currency(locale: locale, symbol: simbolo).format(valor);
  }

  /// Converte o nome salvo (ex.: "dolar") de volta para o enum.
  /// Qualquer valor desconhecido volta para o real.
  static Moeda doNome(String? nome) {
    for (final moeda in values) {
      if (moeda.name == nome) return moeda;
    }
    return Moeda.real;
  }
}

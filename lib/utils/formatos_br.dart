import 'package:intl/intl.dart';

/// Formatações usadas nas telas financeiras do DinDin.
class FormatosBR {
  FormatosBR._();

  static final NumberFormat _moeda =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final NumberFormat _percentual = NumberFormat('0.#', 'pt_BR');

  static const List<String> _meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static String moeda(double valor) => _moeda.format(valor);

  /// Recebe o valor em pontos percentuais: 66.7 -> "66,7%".
  static String percentual(double valor) => '${_percentual.format(valor)}%';

  /// Trunca em uma casa para evitar exibir 100% quando a regra ainda está <100%.
  static String percentualTruncado(double valor) =>
      percentual((valor * 10).floor() / 10);

  static String valorParaCampo(double valor) =>
      valor.toStringAsFixed(2).replaceAll('.', ',');

  static String nomeDoMes(int mes) {
    if (mes < 1 || mes > 12) return '';
    return _meses[mes - 1];
  }
}

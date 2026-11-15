import '../models/transaction_model.dart';

/// Faixas de alerta do orçamento mensal.
enum NivelOrcamento { controlado, atencao, proximo, atingido, excedido }

/// Regras financeiras mensais em funções puras (sem Provider, sem banco).
/// Os cálculos são feitos em centavos para reduzir erros de ponto flutuante
/// em comparações monetárias, como o limite exato do orçamento.
class CalculosMensais {
  CalculosMensais._();

  static int _centavos(double valor) => (valor * 100).round();

  /// Retorna true quando [data] está no mesmo mês e ano de [referencia].
  static bool ehDoMes(DateTime data, DateTime referencia) =>
      data.year == referencia.year && data.month == referencia.month;

  /// Soma somente despesas do mês de [referencia]. Receitas são ignoradas.
  static double gastoDoMes(
    List<TransactionModel> transacoes,
    DateTime referencia,
  ) {
    var totalCentavos = 0;
    for (final t in transacoes) {
      if (t.tipo == TransactionType.despesa && ehDoMes(t.data, referencia)) {
        totalCentavos += _centavos(t.valor);
      }
    }
    return totalCentavos / 100;
  }

  /// Soma somente receitas do mês de [referencia]. Despesas são ignoradas.
  static double receitaDoMes(
    List<TransactionModel> transacoes,
    DateTime referencia,
  ) {
    var totalCentavos = 0;
    for (final t in transacoes) {
      if (t.tipo == TransactionType.receita && ehDoMes(t.data, referencia)) {
        totalCentavos += _centavos(t.valor);
      }
    }
    return totalCentavos / 100;
  }

  /// Despesas do mês agrupadas por categoria, da maior para a menor.
  static Map<String, double> despesasPorCategoria(
    List<TransactionModel> transacoes,
    DateTime referencia,
  ) {
    final centavosPorCategoria = <String, int>{};

    for (final t in transacoes) {
      if (t.tipo != TransactionType.despesa || !ehDoMes(t.data, referencia)) {
        continue;
      }

      final categoria =
          t.categoria.trim().isEmpty ? 'Outros' : t.categoria.trim();
      centavosPorCategoria[categoria] =
          (centavosPorCategoria[categoria] ?? 0) + _centavos(t.valor);
    }

    final ordenadas = centavosPorCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {for (final e in ordenadas) e.key: e.value / 100};
  }

  /// Fração do limite já utilizada (0.675 = 67,5%). Pode passar de 1.0.
  /// Sem limite válido retorna 0 para evitar divisão por zero.
  static double fracaoUsada(double gasto, double? limite) {
    if (limite == null) return 0;
    final limiteCentavos = _centavos(limite);
    if (limiteCentavos <= 0) return 0;
    return _centavos(gasto) / limiteCentavos;
  }

  /// Classifica o consumo do orçamento por faixa de alerta.
  static NivelOrcamento nivel(double gasto, double limite) {
    final g = _centavos(gasto);
    final l = _centavos(limite);

    if (l <= 0) return NivelOrcamento.controlado;
    if (g > l) return NivelOrcamento.excedido;
    if (g == l) return NivelOrcamento.atingido;
    if (g * 100 >= l * 90) return NivelOrcamento.proximo;
    if (g * 100 >= l * 70) return NivelOrcamento.atencao;
    return NivelOrcamento.controlado;
  }
}

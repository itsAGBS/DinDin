import 'package:flutter_test/flutter_test.dart';
import 'package:DinDin/models/transaction_model.dart';
import 'package:DinDin/utils/calculos_mensais.dart';

TransactionModel _t(TransactionType tipo, double valor, DateTime data) {
  return TransactionModel(
    valor: valor,
    data: data,
    categoria: 'Outros',
    tipo: tipo,
  );
}

void main() {
  test('receitaDoMes soma só receitas do mês pedido', () {
    final transacoes = [
      _t(TransactionType.receita, 100.10, DateTime(2026, 10, 3)),
      _t(TransactionType.receita, 50.20, DateTime(2026, 10, 28)),
      _t(TransactionType.receita, 999, DateTime(2026, 11, 1)),
      _t(TransactionType.despesa, 40, DateTime(2026, 10, 10)),
    ];

    expect(CalculosMensais.receitaDoMes(transacoes, DateTime(2026, 10)), 150.30);
  });

  test('receitaDoMes é zero quando não há receitas', () {
    final transacoes = [
      _t(TransactionType.despesa, 40, DateTime(2026, 10, 10)),
    ];

    expect(CalculosMensais.receitaDoMes(transacoes, DateTime(2026, 10)), 0);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:DinDin/models/transaction_model.dart';
import 'package:DinDin/utils/calculos_mensais.dart';

TransactionModel _despesa(
  double valor,
  DateTime data, [
  String categoria = 'Alimentação',
]) =>
    TransactionModel(
      valor: valor,
      data: data,
      categoria: categoria,
      tipo: TransactionType.despesa,
    );

TransactionModel _receita(double valor, DateTime data) => TransactionModel(
      valor: valor,
      data: data,
      categoria: 'Salário',
      tipo: TransactionType.receita,
    );

void main() {
  final ref = DateTime(2026, 11, 14);
  final noMes = DateTime(2026, 11, 3);

  group('nível do orçamento (limite 2000)', () {
    NivelOrcamento n(double gasto) => CalculosMensais.nivel(gasto, 2000);

    test('gasto 0 -> controlado', () {
      expect(n(0), NivelOrcamento.controlado);
    });
    test('gasto 500 -> controlado', () {
      expect(n(500), NivelOrcamento.controlado);
    });
    test('gasto 1399.99 -> controlado', () {
      expect(n(1399.99), NivelOrcamento.controlado);
    });
    test('gasto 1400 -> atenção', () {
      expect(n(1400), NivelOrcamento.atencao);
    });
    test('gasto 1500 -> atenção', () {
      expect(n(1500), NivelOrcamento.atencao);
    });
    test('gasto 1800 -> próximo', () {
      expect(n(1800), NivelOrcamento.proximo);
    });
    test('gasto 1900 -> próximo', () {
      expect(n(1900), NivelOrcamento.proximo);
    });
    test('gasto 2000 -> atingido', () {
      expect(n(2000), NivelOrcamento.atingido);
    });
    test('gasto 2500 -> excedido', () {
      expect(n(2500), NivelOrcamento.excedido);
    });
  });

  group('gasto do mês', () {
    test('somente receitas -> 0', () {
      final lista = [_receita(5000, noMes)];
      expect(CalculosMensais.gastoDoMes(lista, ref), 0);
    });

    test('receitas não reduzem o orçamento', () {
      final lista = [_receita(5000, noMes), _despesa(1500, noMes)];
      final gasto = CalculosMensais.gastoDoMes(lista, ref);
      expect(gasto, 1500);
      expect(CalculosMensais.fracaoUsada(gasto, 2000), 0.75);
    });

    test('mês anterior não entra', () {
      final lista = [
        _despesa(300, DateTime(2026, 10, 30)),
        _despesa(100, noMes),
      ];
      expect(CalculosMensais.gastoDoMes(lista, ref), 100);
    });

    test('mesmo mês de outro ano não entra', () {
      final lista = [
        _despesa(300, DateTime(2025, 11, 14)),
        _despesa(100, noMes),
      ];
      expect(CalculosMensais.gastoDoMes(lista, ref), 100);
    });

    test('mudança de ano: janeiro ignora dezembro', () {
      final janeiro = DateTime(2027, 1, 5);
      final lista = [
        _despesa(400, DateTime(2026, 12, 31)),
        _despesa(50, janeiro),
      ];
      expect(CalculosMensais.gastoDoMes(lista, janeiro), 50);
    });

    test('centavos não acumulam erro de ponto flutuante', () {
      final lista = [_despesa(0.1, noMes), _despesa(0.2, noMes)];
      expect(CalculosMensais.gastoDoMes(lista, ref), 0.3);
    });

    test('exclusão e edição refletem uma nova lista', () {
      final antes = [_despesa(100, noMes), _despesa(200, noMes)];
      final depoisExcluir = [antes.first];
      final depoisEditar = [_despesa(150, noMes), antes.last];
      expect(CalculosMensais.gastoDoMes(depoisExcluir, ref), 100);
      expect(CalculosMensais.gastoDoMes(depoisEditar, ref), 350);
    });
  });

  group('agregação por categoria', () {
    test('soma categorias e ordena por valor decrescente', () {
      final lista = [
        _despesa(300, noMes),
        _despesa(200, noMes),
        _despesa(150, noMes, 'Transporte'),
        _despesa(100, noMes, 'Lazer'),
        _receita(999, noMes),
        _despesa(80, DateTime(2026, 10, 1), 'Lazer'),
      ];
      final mapa = CalculosMensais.despesasPorCategoria(lista, ref);
      expect(mapa, {
        'Alimentação': 500,
        'Transporte': 150,
        'Lazer': 100,
      });
      expect(mapa.keys.first, 'Alimentação');
    });

    test('sem despesas -> mapa vazio', () {
      expect(
        CalculosMensais.despesasPorCategoria([_receita(10, noMes)], ref),
        isEmpty,
      );
    });
  });

  group('fração usada', () {
    test('sem limite ou limite 0 -> 0', () {
      expect(CalculosMensais.fracaoUsada(500, null), 0);
      expect(CalculosMensais.fracaoUsada(500, 0), 0);
    });

    test('1350 de 2000 -> 0.675', () {
      expect(CalculosMensais.fracaoUsada(1350, 2000), 0.675);
    });
  });
}

import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../theme/app_colors.dart';
import '../utils/calculos_mensais.dart';
import '../utils/formatos_br.dart';

/// Mostra o resumo de [mes] em um bottom sheet.
/// Não mostra nada se o mês não teve nenhuma transação.
Future<void> mostrarResumoMensal(
  BuildContext context, {
  required DateTime mes,
  required List<TransactionModel> transacoes,
  required String Function(double) formatarMoeda,
}) async {
  final temMovimento = transacoes.any((t) => CalculosMensais.ehDoMes(t.data, mes));
  if (!temMovimento) return;

  final receitas = CalculosMensais.receitaDoMes(transacoes, mes);
  final despesas = CalculosMensais.gastoDoMes(transacoes, mes);
  final saldo = ((receitas * 100).round() - (despesas * 100).round()) / 100;
  final topCategorias =
      CalculosMensais.despesasPorCategoria(transacoes, mes).entries.take(3).toList();

  final nomeDoMes = FormatosBR.nomeDoMes(mes.month);
  final titulo = '${nomeDoMes[0].toUpperCase()}${nomeDoMes.substring(1)} de ${mes.year}';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ResumoMensalSheet(
      titulo: titulo,
      receitas: receitas,
      despesas: despesas,
      saldo: saldo,
      topCategorias: topCategorias,
      formatarMoeda: formatarMoeda,
    ),
  );
}

class _ResumoMensalSheet extends StatelessWidget {
  const _ResumoMensalSheet({
    required this.titulo,
    required this.receitas,
    required this.despesas,
    required this.saldo,
    required this.topCategorias,
    required this.formatarMoeda,
  });

  final String titulo;
  final double receitas;
  final double despesas;
  final double saldo;
  final List<MapEntry<String, double>> topCategorias;
  final String Function(double) formatarMoeda;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo do mês',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cores.textoSecundario,
              ),
            ),
            Text(
              titulo,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: cores.textoPrincipal,
              ),
            ),
            const SizedBox(height: 16),
            _LinhaValor(
              rotulo: 'Receitas',
              valor: formatarMoeda(receitas),
              cor: cores.receita,
            ),
            _LinhaValor(
              rotulo: 'Despesas',
              valor: formatarMoeda(despesas),
              cor: cores.despesa,
            ),
            const Divider(height: 24),
            _LinhaValor(
              rotulo: 'Saldo do mês',
              valor: formatarMoeda(saldo),
              cor: saldo < 0 ? cores.despesa : cores.receita,
              destaque: true,
            ),
            if (topCategorias.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Onde você mais gastou',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 8),
              for (final categoria in topCategorias)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        iconeDaCategoria(categoria.key),
                        size: 20,
                        color: cores.textoSecundario,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          categoria.key,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: cores.textoPrincipal,
                          ),
                        ),
                      ),
                      Text(
                        formatarMoeda(categoria.value),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: cores.textoPrincipal,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaValor extends StatelessWidget {
  const _LinhaValor({
    required this.rotulo,
    required this.valor,
    required this.cor,
    this.destaque = false,
  });

  final String rotulo;
  final String valor;
  final Color cor;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            rotulo,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: destaque ? 16 : 14,
              fontWeight: destaque ? FontWeight.w700 : FontWeight.w500,
              color: cores.textoPrincipal,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: destaque ? 18 : 15,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}

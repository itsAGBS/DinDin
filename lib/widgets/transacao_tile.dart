import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../theme/app_colors.dart';

class TransacaoTile extends StatelessWidget {
  final TransactionModel transacao;
  final VoidCallback? onTap;

  const TransacaoTile({super.key, required this.transacao, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final ehReceita = transacao.tipo == TransactionType.receita;
    final cor = ehReceita ? cores.receita : cores.despesa;
    final sinal = ehReceita ? '+' : '-';
    final valorFormatado =
        'R\$ ${transacao.valor.abs().toStringAsFixed(2).replaceAll('.', ',')}';
    final titulo = transacao.temDescricao ? transacao.descricao : transacao.categoria;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: cor.withValues(alpha: 0.10),
      highlightColor: cor.withValues(alpha: 0.05),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cores.cardFundo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cores.borda),
          boxShadow: [
            BoxShadow(
              color: cores.sombra,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconeDaCategoria(transacao.categoria), color: cor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: cores.textoPrincipal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transacao.categoria} • ${DateFormat('dd/MM/yyyy').format(transacao.data)}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: cores.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$sinal$valorFormatado',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

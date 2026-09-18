import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../theme/app_colors.dart';

/// Item de lista usado tanto no dashboard (últimas transações)
/// quanto na tela de histórico completo.
class TransacaoTile extends StatelessWidget {
  final TransactionModel transacao;
  final VoidCallback? onTap;

  const TransacaoTile({super.key, required this.transacao, this.onTap});

  IconData _iconePorCategoria(String categoria) {
    switch (categoria) {
      case 'Alimentação':
        return Icons.restaurant_outlined;
      case 'Transporte':
        return Icons.directions_bus_outlined;
      case 'Moradia':
        return Icons.home_outlined;
      case 'Lazer':
        return Icons.sports_esports_outlined;
      case 'Saúde':
        return Icons.favorite_border;
      case 'Educação':
        return Icons.school_outlined;
      case 'Salário':
        return Icons.payments_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ehReceita = transacao.tipo == TransactionType.receita;
    final cor = ehReceita ? AppColors.receita : AppColors.despesa;
    final sinal = ehReceita ? '+' : '-';
    final valorFormatado =
        'R\$ ${transacao.valor.abs().toStringAsFixed(2).replaceAll('.', ',')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E9F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconePorCategoria(transacao.categoria), color: cor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transacao.descricao,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transacao.categoria} • ${DateFormat('dd/MM/yyyy').format(transacao.data)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.black54,
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

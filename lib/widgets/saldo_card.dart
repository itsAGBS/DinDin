import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Card de destaque que mostra o saldo atual.
/// A cor de fundo muda de acordo com o valor do saldo:
/// vermelho (negativo), verde (positivo) ou navy neutro (zerado).
class SaldoCard extends StatelessWidget {
  final double saldo;

  const SaldoCard({super.key, required this.saldo});

  String _formatarMoeda(double valor) {
    final sinal = valor < 0 ? '-' : '';
    final valorAbsoluto = valor.abs().toStringAsFixed(2).replaceAll('.', ',');
    return '${sinal}R\$ $valorAbsoluto';
  }

  @override
  Widget build(BuildContext context) {
    final corFundo = AppColors.corDoSaldo(saldo);
    final positivo = saldo >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: corFundo.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo atual',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                positivo ? Icons.trending_up : Icons.trending_down,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatarMoeda(saldo),
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

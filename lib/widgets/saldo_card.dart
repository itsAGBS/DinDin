import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
    final cores = context.cores;
    final corFundo = cores.corDoSaldo(saldo);
    final neutro = saldo == 0;
    final positivo = saldo >= 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(20),
        border: neutro && cores.saldoDestaqueBorda != null
            ? Border.all(color: cores.saldoDestaqueBorda!)
            : null,
        boxShadow: [
          BoxShadow(
            color: corFundo.withValues(alpha: 0.25),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  positivo ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: 18,
                ),
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

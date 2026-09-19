import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../theme/app_colors.dart';
import '../widgets/saldo_card.dart';
import '../widgets/transacao_tile.dart';
import 'historico_screen.dart';
import 'transacao_form_screen.dart';
import 'configurar_bloqueio_screen.dart';

/// Tela principal exibida ao abrir o app.
/// Mostra saldo atual, últimas transações e acesso rápido
/// para adicionar receita/despesa.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _abrirFormulario(BuildContext context, TransactionType tipo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransacaoFormScreen(tipoInicial: tipo),
      ),
    );
  }

  void _abrirEdicao(BuildContext context, TransactionModel transacao) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransacaoFormScreen(transacaoExistente: transacao),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        elevation: 0,
        title: const Text(
          'DinDin',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline, color: Colors.black54),
            tooltip: 'Segurança',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConfigurarBloqueioScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: provider.carregando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: () => context.read<TransactionProvider>().carregarDados(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const Text(
                'Olá! 👋',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Aqui está o resumo das suas finanças',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),

              SaldoCard(saldo: provider.saldo),
              const SizedBox(height: 16),

              // Acesso rápido para adicionar receita/despesa
              Row(
                children: [
                  Expanded(
                    child: _BotaoRapido(
                      label: 'Receita',
                      icone: Icons.add_circle_outline,
                      cor: AppColors.receita,
                      onTap: () => _abrirFormulario(context, TransactionType.receita),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BotaoRapido(
                      label: 'Despesa',
                      icone: Icons.remove_circle_outline,
                      cor: AppColors.despesa,
                      onTap: () => _abrirFormulario(context, TransactionType.despesa),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Últimas transações',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoricoScreen()),
                    ),
                    child: const Text(
                      'Ver tudo',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.acao,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              if (provider.ultimasTransacoes.isEmpty)
                const _EstadoVazio()
              else
                ...provider.ultimasTransacoes.map(
                      (t) => TransacaoTile(
                        transacao: t,
                        onTap: () => _abrirEdicao(context, t),
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotaoRapido extends StatelessWidget {
  final String label;
  final IconData icone;
  final Color cor;
  final VoidCallback onTap;

  const _BotaoRapido({
    required this.label,
    required this.icone,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: cor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: cor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: const [
          Icon(Icons.receipt_long_outlined, size: 40, color: Colors.black26),
          SizedBox(height: 8),
          Text(
            'Nenhuma transação ainda',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

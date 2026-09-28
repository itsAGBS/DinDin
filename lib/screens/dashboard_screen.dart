import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../theme/app_colors.dart';
import '../utils/page_transitions.dart';
import '../widgets/dindin_logo.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/saldo_card.dart';
import '../widgets/transacao_tile.dart';
import 'historico_screen.dart';
import 'transacao_form_screen.dart';
import 'configurar_bloqueio_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _abrirFormulario(BuildContext context, TransactionType tipo) {
    Navigator.of(context).push(
      rotaComTransicaoSuave(TransacaoFormScreen(tipoInicial: tipo)),
    );
  }

  void _abrirEdicao(BuildContext context, TransactionModel transacao) {
    Navigator.of(context).push(
      rotaComTransicaoSuave(TransacaoFormScreen(transacaoExistente: transacao)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final cores = context.cores;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: DinDinMark(size: 34),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.lock_outline, color: cores.textoSecundario),
            tooltip: 'Segurança',
            onPressed: () => Navigator.of(context).push(
              rotaComTransicaoSuave(const ConfigurarBloqueioScreen()),
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
              SaldoCard(saldo: provider.saldo),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _BotaoRapido(
                      label: 'Receita',
                      icone: Icons.add_circle_outline,
                      cor: cores.receita,
                      onTap: () => _abrirFormulario(context, TransactionType.receita),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BotaoRapido(
                      label: 'Despesa',
                      icone: Icons.remove_circle_outline,
                      cor: cores.despesa,
                      onTap: () => _abrirFormulario(context, TransactionType.despesa),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Últimas transações',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cores.textoPrincipal,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      rotaComTransicaoSuave(const HistoricoScreen()),
                    ),
                    child: Text(
                      'Ver tudo',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: cores.azul,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              if (provider.ultimasTransacoes.isEmpty)
                const EstadoVazio(
                  icone: Icons.receipt_long_outlined,
                  titulo: 'Nenhuma transação ainda',
                  subtitulo: 'Toque em Receita ou Despesa para começar',
                )
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: cor.withValues(alpha: 0.12),
        highlightColor: cor.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cor.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: cor.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
      ),
    );
  }
}

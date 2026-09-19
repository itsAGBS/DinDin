import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../theme/app_colors.dart';
import '../widgets/transacao_tile.dart';
import 'transacao_form_screen.dart';

/// Tela de histórico: listagem completa de transações cadastradas,
/// ordenadas por data (mais recentes primeiro), com filtro opcional
/// por tipo (todas / receitas / despesas).
class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  TransactionType? _filtro; // null = todas

  void _abrirCadastro(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransacaoFormScreen()),
    );
  }

  void _abrirEdicao(BuildContext context, TransactionModel transacao) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransacaoFormScreen(transacaoExistente: transacao),
      ),
    );
  }

  Future<bool> _confirmarExclusao(BuildContext context, TransactionModel t) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Excluir transação',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Tem certeza que deseja excluir '
          '"${t.temDescricao ? t.descricao : t.categoria}"? '
          'Essa ação não pode ser desfeita.',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(fontFamily: 'Poppins')),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: AppColors.despesa),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
    return confirmou ?? false;
  }

  List<TransactionModel> _ordenarEFiltrar(List<TransactionModel> transacoes) {
    final lista = transacoes.where((t) {
      if (_filtro == null) return true;
      return t.tipo == _filtro;
    }).toList();

    lista.sort((a, b) => b.data.compareTo(a.data)); // mais recentes primeiro
    return lista;
  }

  Map<String, List<TransactionModel>> _agruparPorDia(List<TransactionModel> transacoes) {
    final grupos = <String, List<TransactionModel>>{};
    for (final t in transacoes) {
      final chave = DateFormat('dd/MM/yyyy').format(t.data);
      grupos.putIfAbsent(chave, () => []).add(t);
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final transacoes = _ordenarEFiltrar(provider.transacoes);
    final grupos = _agruparPorDia(transacoes);

    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Histórico',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
      ),
      body: provider.carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _ChipFiltro(
                  label: 'Todas',
                  selecionado: _filtro == null,
                  cor: AppColors.destaque,
                  onTap: () => setState(() => _filtro = null),
                ),
                const SizedBox(width: 8),
                _ChipFiltro(
                  label: 'Receitas',
                  selecionado: _filtro == TransactionType.receita,
                  cor: AppColors.receita,
                  onTap: () => setState(() => _filtro = TransactionType.receita),
                ),
                const SizedBox(width: 8),
                _ChipFiltro(
                  label: 'Despesas',
                  selecionado: _filtro == TransactionType.despesa,
                  cor: AppColors.despesa,
                  onTap: () => setState(() => _filtro = TransactionType.despesa),
                ),
              ],
            ),
          ),
          Expanded(
            child: transacoes.isEmpty
                ? const Center(
              child: Text(
                'Nenhuma transação encontrada',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.black45),
              ),
            )
                : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: grupos.entries.map((entrada) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Text(
                        entrada.key,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                    ...entrada.value.map(
                      (t) => Dismissible(
                        key: ValueKey(t.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.despesa,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        confirmDismiss: (_) => _confirmarExclusao(context, t),
                        onDismissed: (_) =>
                            context.read<TransactionProvider>().excluirTransacao(t.id!),
                        child: TransacaoTile(
                          transacao: t,
                          onTap: () => _abrirEdicao(context, t),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.acao,
        onPressed: () => _abrirCadastro(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String label;
  final bool selecionado;
  final Color cor;
  final VoidCallback onTap;

  const _ChipFiltro({
    required this.label,
    required this.selecionado,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? cor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selecionado ? cor : const Color(0xFFE5E9F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selecionado ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}

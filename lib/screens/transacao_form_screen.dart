import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';

/// Tela única para cadastrar uma nova transação ou editar uma já existente.
///
/// - [tipoInicial] pré-seleciona receita/despesa quando vem do atalho
///   rápido do dashboard.
/// - [transacaoExistente] preenche o formulário e faz a tela salvar via
///   [TransactionProvider.editarTransacao] em vez de criar um registro novo.
class TransacaoFormScreen extends StatefulWidget {
  const TransacaoFormScreen({
    super.key,
    this.tipoInicial = TransactionType.despesa,
    this.transacaoExistente,
  });

  final TransactionType tipoInicial;
  final TransactionModel? transacaoExistente;

  bool get emEdicao => transacaoExistente != null;

  @override
  State<TransacaoFormScreen> createState() => _TransacaoFormScreenState();
}

class _TransacaoFormScreenState extends State<TransacaoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();

  late TransactionType _tipo;
  late DateTime _data;
  CategoryModel? _categoria;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final existente = widget.transacaoExistente;

    _tipo = existente?.tipo ?? widget.tipoInicial;
    _data = existente?.data ?? DateTime.now();

    if (existente != null) {
      _valorController.text = existente.valor.toStringAsFixed(2).replaceAll('.', ',');
      _descricaoController.text = existente.descricao;
      _categoria = categoriasPadrao.firstWhere(
        (c) => c.nome == existente.categoria && c.tipo == existente.tipo,
        orElse: () => categoriasPorTipo(existente.tipo).first,
      );
    }
  }

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  /// Ao trocar o tipo (receita/despesa), a categoria selecionada some se
  /// ela não pertencer à lista de categorias do novo tipo.
  void _mudarTipo(TransactionType novoTipo) {
    setState(() {
      _tipo = novoTipo;
      if (_categoria != null && _categoria!.tipo != novoTipo) {
        _categoria = null;
      }
    });
  }

  Future<void> _escolherData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selecionada != null) {
      setState(() => _data = selecionada);
    }
  }

  Future<void> _salvar() async {
    final formularioValido = _formKey.currentState!.validate();
    if (!formularioValido || _categoria == null) {
      if (_categoria == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione uma categoria.')),
        );
      }
      return;
    }

    setState(() => _salvando = true);

    final valor = double.parse(_valorController.text.replaceAll(',', '.'));
    final provider = context.read<TransactionProvider>();

    final transacao = TransactionModel(
      id: widget.transacaoExistente?.id,
      valor: valor,
      data: _data,
      categoria: _categoria!.nome,
      tipo: _tipo,
      descricao: _descricaoController.text,
    );

    if (widget.emEdicao) {
      await provider.editarTransacao(transacao);
    } else {
      await provider.adicionarTransacao(transacao);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final corDoTipo = _tipo == TransactionType.receita
        ? AppColors.receita
        : AppColors.despesa;

    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          widget.emEdicao ? 'Editar transação' : 'Nova transação',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SegmentoTipo(
                        label: 'Despesa',
                        icone: Icons.remove_circle_outline,
                        cor: AppColors.despesa,
                        selecionado: _tipo == TransactionType.despesa,
                        onTap: () => _mudarTipo(TransactionType.despesa),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SegmentoTipo(
                        label: 'Receita',
                        icone: Icons.add_circle_outline,
                        cor: AppColors.receita,
                        selecionado: _tipo == TransactionType.receita,
                        onTap: () => _mudarTipo(TransactionType.receita),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _valorController,
                  style: const TextStyle(fontFamily: 'Poppins'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: corDoTipo, width: 1.5),
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Digite o valor da transação';
                    }
                    final numero = double.tryParse(valor.replaceAll(',', '.'));
                    if (numero == null) {
                      return 'Digite um valor numérico válido';
                    }
                    if (numero <= 0) {
                      return 'O valor precisa ser maior que zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _escolherData,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data',
                      labelStyle: const TextStyle(fontFamily: 'Poppins'),
                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_data),
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Categoria',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: categoriasPorTipo(_tipo).map((categoria) {
                    final selecionada = categoria == _categoria;
                    return _CategoriaChip(
                      categoria: categoria,
                      corSelecionada: corDoTipo,
                      selecionada: selecionada,
                      onTap: () => setState(() => _categoria = categoria),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descricaoController,
                  style: const TextStyle(fontFamily: 'Poppins'),
                  decoration: InputDecoration(
                    labelText: 'Descrição (opcional)',
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLength: 80,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _salvando ? null : _salvar,
                  style: FilledButton.styleFrom(
                    backgroundColor: corDoTipo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _salvando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.emEdicao ? 'Salvar alterações' : 'Salvar',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentoTipo extends StatelessWidget {
  const _SegmentoTipo({
    required this.label,
    required this.icone,
    required this.cor,
    required this.selecionado,
    required this.onTap,
  });

  final String label;
  final IconData icone;
  final Color cor;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selecionado ? cor.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selecionado ? cor : const Color(0xFFE5E9F0),
            width: selecionado ? 1.5 : 1,
          ),
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

class _CategoriaChip extends StatelessWidget {
  const _CategoriaChip({
    required this.categoria,
    required this.corSelecionada,
    required this.selecionada,
    required this.onTap,
  });

  final CategoryModel categoria;
  final Color corSelecionada;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selecionada ? corSelecionada.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionada ? corSelecionada : const Color(0xFFE5E9F0),
            width: selecionada ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              categoria.icone,
              size: 18,
              color: selecionada ? corSelecionada : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              categoria.nome,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: selecionada ? FontWeight.w600 : FontWeight.normal,
                color: selecionada ? corSelecionada : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

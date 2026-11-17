import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatos_br.dart';

/// Tela para definir ou editar o limite de gastos mensal.
class OrcamentoScreen extends StatefulWidget {
  const OrcamentoScreen({super.key});

  @override
  State<OrcamentoScreen> createState() => _OrcamentoScreenState();
}

class _OrcamentoScreenState extends State<OrcamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final limiteAtual = context.read<TransactionProvider>().limiteMensal;
    _controller = TextEditingController(
      text: limiteAtual == null ? '' : FormatosBR.valorParaCampo(limiteAtual),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Aceita 2000, 2000,50 ou 2000.50.
  double? _lerValor(String? texto) {
    final limpo = (texto ?? '').trim();
    if (!RegExp(r'^\d+([\.,]\d{1,2})?$').hasMatch(limpo)) return null;
    return double.tryParse(limpo.replaceAll(',', '.'));
  }

  String? _validar(String? texto) {
    final valor = _lerValor(texto);
    if (valor == null) return 'Informe um valor válido (ex.: 2000,00)';
    if (valor <= 0) return 'O valor deve ser maior que zero';
    return null;
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!_formKey.currentState!.validate()) return;

    final valor = _lerValor(_controller.text)!;
    setState(() => _salvando = true);

    try {
      await context.read<TransactionProvider>().definirLimiteMensal(valor);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o orçamento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cor),
        );

    return Scaffold(
      backgroundColor: cores.fundo,
      appBar: AppBar(
        title: Text(
          'Orçamento mensal',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: cores.textoPrincipal,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Text(
                'Quanto você pretende gastar por mês?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Somente despesas entram nesse acompanhamento. Receitas não reduzem o valor gasto.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: cores.textoSecundario,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                validator: _validar,
                onFieldSubmitted: (_) => _salvar(),
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: cores.textoPrincipal,
                ),
                decoration: InputDecoration(
                  prefixText: 'R\$ ',
                  prefixStyle: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: cores.textoSecundario,
                  ),
                  hintText: '2000,00',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: cores.textoSecundario.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: cores.cardFundo,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  enabledBorder: borda(cores.borda),
                  focusedBorder: borda(cores.azul),
                  errorBorder: borda(cores.despesa),
                  focusedErrorBorder: borda(cores.despesa),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _salvando ? null : _salvar,
                style: FilledButton.styleFrom(
                  backgroundColor: cores.azul,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Salvar orçamento',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

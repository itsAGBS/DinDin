import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/calculos_mensais.dart';
import '../utils/formatos_br.dart';

/// Card de acompanhamento do orçamento mensal.
/// Recebe dados prontos e não acessa Provider ou banco diretamente.
class OrcamentoMensalCard extends StatelessWidget {
  final double? limite;
  final double gasto;
  final DateTime referencia;
  final VoidCallback onConfigurar;

  const OrcamentoMensalCard({
    super.key,
    required this.limite,
    required this.gasto,
    required this.referencia,
    required this.onConfigurar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final limiteDefinido = limite;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cores.cardFundo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cores.borda),
        boxShadow: [
          BoxShadow(
            color: cores.sombra,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Orçamento de ${FormatosBR.nomeDoMes(referencia.month)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cores.textoPrincipal,
                  ),
                ),
              ),
              if (limiteDefinido != null)
                TextButton.icon(
                  onPressed: onConfigurar,
                  icon: Icon(Icons.edit_outlined, size: 16, color: cores.azul),
                  label: Text(
                    'Editar limite',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cores.azul,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (limiteDefinido == null)
            _SemOrcamento(onDefinir: onConfigurar)
          else
            _ComOrcamento(limite: limiteDefinido, gasto: gasto),
        ],
      ),
    );
  }
}

class _SemOrcamento extends StatelessWidget {
  final VoidCallback onDefinir;

  const _SemOrcamento({required this.onDefinir});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Você ainda não definiu um orçamento mensal.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: cores.textoSecundario,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onDefinir,
          style: FilledButton.styleFrom(
            backgroundColor: cores.azul,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Definir orçamento',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ComOrcamento extends StatelessWidget {
  final double limite;
  final double gasto;

  const _ComOrcamento({required this.limite, required this.gasto});

  Color _corDoNivel(AppPalette cores, NivelOrcamento nivel) {
    return switch (nivel) {
      NivelOrcamento.controlado => cores.receita,
      NivelOrcamento.atencao => cores.alerta,
      _ => cores.despesa,
    };
  }

  IconData _iconeDoNivel(NivelOrcamento nivel) {
    return switch (nivel) {
      NivelOrcamento.controlado => Icons.check_circle_outline,
      NivelOrcamento.atencao => Icons.warning_amber_rounded,
      _ => Icons.error_outline,
    };
  }

  String _mensagem(NivelOrcamento nivel, double fracao, double excedente) {
    return switch (nivel) {
      NivelOrcamento.controlado => 'Seu orçamento está sob controle.',
      NivelOrcamento.atencao =>
        'Atenção: você já utilizou ${FormatosBR.percentualTruncado(fracao * 100)} do orçamento.',
      NivelOrcamento.proximo =>
        'Cuidado: você está próximo do limite mensal.',
      NivelOrcamento.atingido => 'Você atingiu seu limite mensal.',
      NivelOrcamento.excedido =>
        'Orçamento excedido em ${FormatosBR.moeda(excedente)}.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final nivel = CalculosMensais.nivel(gasto, limite);
    final fracao = CalculosMensais.fracaoUsada(gasto, limite);
    final cor = _corDoNivel(cores, nivel);
    final excedido = nivel == NivelOrcamento.excedido;
    final excedente = math.max(0.0, gasto - limite).toDouble();
    final restante = math.max(0.0, limite - gasto).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${FormatosBR.moeda(gasto)} de ${FormatosBR.moeda(limite)}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: cores.textoSecundario,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: fracao.clamp(0.0, 1.0).toDouble(),
                  minHeight: 10,
                  backgroundColor: cores.overlaySutil,
                  valueColor: AlwaysStoppedAnimation<Color>(cor),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              FormatosBR.percentualTruncado(fracao * 100),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          excedido ? 'Excedido em' : 'Você ainda pode gastar',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: cores.textoSecundario,
          ),
        ),
        Text(
          FormatosBR.moeda(excedido ? excedente : restante),
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: excedido ? cores.despesa : cores.textoPrincipal,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_iconeDoNivel(nivel), size: 18, color: cor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _mensagem(nivel, fracao, excedente),
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: cor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_estilo.dart';
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
      padding: const EdgeInsets.all(AppEstilo.paddingCard),
      decoration: AppEstilo.cardDecoracao(cores),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconeChip(
                icone: Icons.account_balance_wallet_outlined,
                cor: cores.azul,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orçamento de ${FormatosBR.nomeDoMes(referencia.month)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppEstilo.titulo(cores),
                    ),
                    Text(
                      'Acompanhamento do mês',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppEstilo.subtitulo(cores),
                    ),
                  ],
                ),
              ),
              if (limiteDefinido != null)
                IconButton(
                  onPressed: onConfigurar,
                  tooltip: 'Editar limite',
                  icon: Icon(Icons.edit_outlined, size: 18, color: cores.azul),
                  style: IconButton.styleFrom(
                    backgroundColor: cores.azul.withValues(alpha: 0.10),
                    fixedSize: const Size(40, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppEstilo.raioIcone),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
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
          style: AppEstilo.subtitulo(cores, tamanho: 13),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton.icon(
            onPressed: onDefinir,
            icon: const Icon(Icons.add_rounded, size: 20),
            style: FilledButton.styleFrom(
              backgroundColor: cores.azul,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppEstilo.raioIcone),
              ),
            ),
            label: Text(
              'Definir orçamento',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
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
      NivelOrcamento.proximo => 'Cuidado: você está próximo do limite mensal.',
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    excedido ? 'Excedido em' : 'Você ainda pode gastar',
                    style: AppEstilo.subtitulo(cores),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      FormatosBR.moeda(excedido ? excedente : restante),
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: excedido ? cores.despesa : cores.textoPrincipal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                FormatosBR.percentualTruncado(fracao * 100),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: fracao.clamp(0.0, 1.0).toDouble(),
            minHeight: 10,
            backgroundColor: cores.overlaySutil,
            valueColor: AlwaysStoppedAnimation<Color>(cor),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _Indicador(
                rotulo: 'Gasto',
                valor: FormatosBR.moeda(gasto),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: _Indicador(
                rotulo: 'Limite',
                valor: FormatosBR.moeda(limite),
                alinharADireita: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppEstilo.raioIcone),
          ),
          child: Row(
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
        ),
      ],
    );
  }
}

class _Indicador extends StatelessWidget {
  final String rotulo;
  final String valor;
  final bool alinharADireita;

  const _Indicador({
    required this.rotulo,
    required this.valor,
    this.alinharADireita = false,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Column(
      crossAxisAlignment: alinharADireita
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: AppEstilo.subtitulo(cores, tamanho: 11.5)),
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: cores.textoPrincipal,
          ),
        ),
      ],
    );
  }
}

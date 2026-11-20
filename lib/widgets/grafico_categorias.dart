import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_estilo.dart';
import '../utils/formatos_br.dart';

/// Gráfico de rosca das despesas do mês por categoria.
/// Recebe o Map já agregado e não conhece Provider.
class GraficoCategorias extends StatelessWidget {
  final Map<String, double> despesasPorCategoria;
  final DateTime referencia;

  /// Número máximo de fatias exibidas no gráfico.
  static const int _maxFatias = 6;

  const GraficoCategorias({
    super.key,
    required this.despesasPorCategoria,
    required this.referencia,
  });

  List<Color> _paleta(AppPalette cores) => [
    cores.azul,
    cores.alerta,
    const Color(0xFF8B5CF6),
    const Color(0xFF14B8A6),
    const Color(0xFFEC4899),
    const Color(0xFF06B6D4),
  ];

  List<_Fatia> _montarFatias(AppPalette cores) {
    final ordenadas =
        despesasPorCategoria.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    if (ordenadas.isEmpty) return const [];

    final paleta = _paleta(cores);
    final fatias = <_Fatia>[];

    // Até seis categorias: mostra todas. Acima disso: cinco principais + resto.
    if (ordenadas.length <= _maxFatias) {
      for (var i = 0; i < ordenadas.length; i++) {
        fatias.add(_Fatia(ordenadas[i].key, ordenadas[i].value, paleta[i]));
      }
      return fatias;
    }

    final principais = _maxFatias - 1;
    for (var i = 0; i < principais; i++) {
      fatias.add(_Fatia(ordenadas[i].key, ordenadas[i].value, paleta[i]));
    }

    final resto = ordenadas
        .skip(principais)
        .fold<double>(0, (soma, e) => soma + e.value);
    fatias.add(_Fatia('Demais categorias', resto, cores.textoSecundario));

    return fatias;
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final fatias = _montarFatias(cores);
    final total = fatias.fold<double>(0, (soma, f) => soma + f.valor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppEstilo.paddingCard),
      decoration: AppEstilo.cardDecoracao(cores),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconeChip(icone: Icons.donut_large_rounded, cor: cores.azul),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastos por categoria',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppEstilo.titulo(cores),
                    ),
                    Text(
                      FormatosBR.nomeDoMes(referencia.month),
                      style: AppEstilo.subtitulo(cores),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (fatias.isEmpty || total <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.donut_large_rounded,
                      size: 32,
                      color: cores.textoSecundario.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Nenhuma despesa neste mês para analisar.',
                      textAlign: TextAlign.center,
                      style: AppEstilo.subtitulo(cores, tamanho: 13),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 62,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(enabled: false),
                      sections: [
                        for (final f in fatias)
                          PieChartSectionData(
                            value: f.valor,
                            color: f.cor,
                            radius: 26,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 104,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total', style: AppEstilo.subtitulo(cores)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            FormatosBR.moeda(total),
                            maxLines: 1,
                            style: AppEstilo.titulo(cores),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: cores.borda),
            const SizedBox(height: 6),
            for (final f in fatias)
              _LinhaLegenda(fatia: f, percentual: f.valor / total * 100),
          ],
        ],
      ),
    );
  }
}

class _Fatia {
  final String nome;
  final double valor;
  final Color cor;

  const _Fatia(this.nome, this.valor, this.cor);
}

class _LinhaLegenda extends StatelessWidget {
  final _Fatia fatia;
  final double percentual;

  const _LinhaLegenda({required this.fatia, required this.percentual});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final estilo = GoogleFonts.poppins(
      fontSize: 13,
      color: cores.textoPrincipal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: fatia.cor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fatia.nome,
              style: estilo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            FormatosBR.moeda(fatia.valor),
            style: estilo.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(
            width: 58,
            child: Text(
              FormatosBR.percentual(percentual),
              textAlign: TextAlign.right,
              style: estilo.copyWith(color: cores.textoSecundario),
            ),
          ),
        ],
      ),
    );
  }
}

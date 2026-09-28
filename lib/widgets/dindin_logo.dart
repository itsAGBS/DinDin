import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Ícone da marca DinDin: quadrado arredondado escuro com a moeda verde e o
/// símbolo de seta para cima. Desenhado em vetor, então fica nítido em
/// qualquer tamanho e igual nos modos claro e escuro.
class DinDinMark extends StatelessWidget {
  final double size;

  const DinDinMark({super.key, this.size = 40});

  static const Color _fundo = Color(0xFF172033);
  static const Color _moeda = AppColors.receita;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final centro = Offset(s / 2, s / 2);

    // Quadrado arredondado
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, s, s),
        Radius.circular(s * 0.2374),
      ),
      Paint()..color = DinDinMark._fundo,
    );

    // Moeda verde
    canvas.drawCircle(
      centro,
      s * 0.3408,
      Paint()..color = DinDinMark._moeda,
    );

    // Seta (Λ) com pontas arredondadas
    final seta = Path()
      ..moveTo(centro.dx - s * 0.2123, centro.dy + s * 0.1522)
      ..lineTo(centro.dx, centro.dy - s * 0.2039)
      ..lineTo(centro.dx + s * 0.2123, centro.dy + s * 0.1522);

    canvas.drawPath(
      seta,
      Paint()
        ..color = DinDinMark._fundo
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.067
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Logo completa: ícone + "DinDin". O texto se adapta ao tema:
/// "Din" na cor de texto principal e "Din" em verde (mais claro no modo escuro).
class DinDinLogo extends StatelessWidget {
  /// Tamanho do ícone. O texto é proporcional a ele.
  final double markSize;

  const DinDinLogo({super.key, this.markSize = 64});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final estilo = GoogleFonts.poppins(
      fontSize: markSize * 0.58,
      fontWeight: FontWeight.w700,
      height: 1.1,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DinDinMark(size: markSize),
        SizedBox(width: markSize * 0.3),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Din', style: estilo.copyWith(color: cores.textoPrincipal)),
              TextSpan(text: 'Din', style: estilo.copyWith(color: cores.receita)),
            ],
          ),
        ),
      ],
    );
  }
}

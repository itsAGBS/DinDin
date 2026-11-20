import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tokens visuais compartilhados pelos cards do Dashboard.
/// Contém apenas estilo, sem regras de negócio.
class AppEstilo {
  AppEstilo._();

  static const double raioCard = 20;
  static const double raioItem = 16;
  static const double raioIcone = 12;
  static const double paddingCard = 18;
  static const double espacoCard = 16;
  static const double espacoSecao = 24;

  static BoxDecoration cardDecoracao(
    AppPalette cores, {
    double raio = raioCard,
    double blur = 16,
    double deslocamentoY = 6,
  }) {
    return BoxDecoration(
      color: cores.cardFundo,
      borderRadius: BorderRadius.circular(raio),
      border: Border.all(color: cores.borda),
      boxShadow: [
        BoxShadow(
          color: cores.sombra,
          blurRadius: blur,
          offset: Offset(0, deslocamentoY),
        ),
      ],
    );
  }

  static TextStyle titulo(AppPalette cores) => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: cores.textoPrincipal,
  );

  static TextStyle subtitulo(AppPalette cores, {double tamanho = 12}) =>
      GoogleFonts.poppins(fontSize: tamanho, color: cores.textoSecundario);
}

/// Bloco arredondado com ícone colorido usado nos cabeçalhos dos cards.
class IconeChip extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final double tamanho;

  const IconeChip({
    super.key,
    required this.icone,
    required this.cor,
    this.tamanho = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppEstilo.raioIcone),
      ),
      child: Icon(icone, color: cor, size: tamanho * 0.5),
    );
  }
}

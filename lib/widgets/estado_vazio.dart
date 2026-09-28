import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    this.subtitulo,
  });

  final IconData icone;
  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cores.overlaySutil,
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 30, color: cores.textoSecundario),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: cores.textoPrincipal,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cores.textoSecundario),
            ),
          ],
        ],
      ),
    );
  }
}

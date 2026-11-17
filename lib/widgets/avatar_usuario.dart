import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/foto_perfil_provider.dart';
import '../theme/app_colors.dart';

/// Foto de perfil redonda. Prioridade: foto escolhida no app, foto da conta
/// Google e, por último, as iniciais do nome (ou do e-mail).
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({super.key, this.raio = 18});

  final double raio;

  String _iniciais(String? nome, String? email) {
    final base = (nome != null && nome.trim().isNotEmpty) ? nome : email;
    if (base == null || base.trim().isEmpty) return '';

    final partes = base.trim().split(RegExp(r'\s+'));
    final primeira = partes.first.characters.first;
    final segunda = partes.length > 1 ? partes.last.characters.first : '';
    return (primeira + segunda).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final user = context.watch<AuthProvider>().user;
    final caminho = context.watch<FotoPerfilProvider>().caminho;

    ImageProvider? imagem;
    if (caminho != null) {
      imagem = FileImage(File(caminho));
    } else if (user?.photoURL != null) {
      imagem = NetworkImage(user!.photoURL!);
    }

    final iniciais = _iniciais(user?.displayName, user?.email);

    return CircleAvatar(
      radius: raio,
      backgroundColor: cores.azul.withValues(alpha: 0.15),
      foregroundImage: imagem,
      // Se a imagem de rede falhar, as iniciais continuam visíveis.
      onForegroundImageError: imagem == null ? null : (_, __) {},
      child: iniciais.isEmpty
          ? Icon(Icons.person, size: raio, color: cores.azul)
          : Text(
              iniciais,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: raio * 0.8,
                color: cores.azul,
              ),
            ),
    );
  }
}

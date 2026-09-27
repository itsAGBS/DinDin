import 'package:flutter/material.dart';

Route<T> rotaComTransicaoSuave<T>(Widget tela) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) => tela,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curva = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curva,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curva),
          child: child,
        ),
      );
    },
  );
}


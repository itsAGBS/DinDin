import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';
import 'screens/bloqueio_screen.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/bloqueio_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/login_screen.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DinDinApp());
}

ThemeData _construirTema({required AppPalette paleta, required Brightness brilho}) {
  final fontFamily = GoogleFonts.poppins().fontFamily;

  return ThemeData(
    useMaterial3: true,
    brightness: brilho,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: paleta.fundo,
    extensions: [paleta],
    colorScheme: ColorScheme.fromSeed(
      seedColor: paleta.azul,
      brightness: brilho,
      primary: paleta.azul,
      secondary: paleta.saldoDestaqueFundo,
      error: paleta.despesa,
      surface: paleta.cardFundo,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: paleta.fundo,
      foregroundColor: paleta.textoPrincipal,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: paleta.textoPrincipal,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      color: paleta.cardFundo,
      surfaceTintColor: Colors.transparent,
      shadowColor: paleta.sombra,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: paleta.cardFundo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(fontFamily: fontFamily, color: paleta.textoSecundario),
      hintStyle: TextStyle(fontFamily: fontFamily, color: paleta.textoSecundario),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: paleta.borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: paleta.azul, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: paleta.despesa),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: paleta.despesa, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: paleta.azul,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: paleta.textoPrincipal,
        side: BorderSide(color: paleta.borda),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: paleta.azul,
        textStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: paleta.azul),
    dividerTheme: DividerThemeData(color: paleta.borda, space: 32),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

class DinDinApp extends StatelessWidget {
  const DinDinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BloqueioProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()..carregarDados()),
      ],
      child: MaterialApp(
        title: 'DinDin',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: _construirTema(paleta: AppPalette.claro, brilho: Brightness.light),
        darkTheme: _construirTema(paleta: AppPalette.escuro, brilho: Brightness.dark),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.carregando:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.naoAutenticado:
        return const LoginScreen();
      case AuthStatus.autenticado:
        return const _PortaoDeBloqueio();
    }
  }
}

class _PortaoDeBloqueio extends StatelessWidget {
  const _PortaoDeBloqueio();

  @override
  Widget build(BuildContext context) {
    final bloqueio = context.watch<BloqueioProvider>();

    switch (bloqueio.status) {
      case StatusBloqueio.carregando:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case StatusBloqueio.bloqueado:
        return const BloqueioScreen();
      case StatusBloqueio.desativado:
      case StatusBloqueio.desbloqueado:
        return const DashboardScreen();
    }
  }
}

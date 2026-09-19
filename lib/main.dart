import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/dashboard_screen.dart';
import 'screens/bloqueio_screen.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/bloqueio_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DinDinApp());
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
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Decide qual tela mostrar de acordo com o estado de autenticação do
/// Firebase: carregando, tela de login, ou o portão de bloqueio local
/// (que por sua vez decide entre a tela de PIN/biometria e o dashboard).
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

/// Só é alcançado quando o Firebase já confirmou o login. Aqui decidimos
/// se ainda falta pedir biometria/PIN antes de liberar o dashboard.
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

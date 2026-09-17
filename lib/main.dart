import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'models/transaction_model.dart';
import 'providers/auth_provider.dart';
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

/// Decide qual tela mostrar de acordo com o estado de autenticação:
/// tela de carregamento enquanto o Firebase resolve a sessão, tela de
/// login se não houver ninguém logado, ou o app em si se houver.
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
        return const TelaTesteBanco();
    }
  }
}

// Tela temporaria so para testar se o banco de dados local esta funcionando.
// Sera substituida pelo Dashboard de verdade.
class TelaTesteBanco extends StatelessWidget {
  const TelaTesteBanco({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DinDin - Teste do banco'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => auth.sair(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (auth.user?.email != null)
              Text('Logado como: ${auth.user!.email}'),
            const SizedBox(height: 12),
            Text('Saldo atual: R\$ ${provider.saldo.toStringAsFixed(2)}\n'
                'Transacoes: ${provider.transacoes.length}'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<TransactionProvider>().adicionarTransacao(
            TransactionModel(
              descricao: 'Teste',
              valor: 50,
              data: DateTime.now(),
              categoria: 'Outros',
              tipo: TransactionType.despesa,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

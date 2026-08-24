import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';

void main() {
  runApp(const AppFinanceiro());
}

class AppFinanceiro extends StatelessWidget {
  const AppFinanceiro({super.key});

  @override
  Widget build(BuildContext context) {
    // Todo o app fica "dentro" do ChangeNotifierProvider.
    // Qualquer tela, em qualquer nivel, consegue acessar o AppState.
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'App Financeiro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const TelaTeste(),
      ),
    );
  }
}

// Tela temporaria, so para confirmar que o Provider esta funcionando.
// Sera substituida pelo Dashboard de verdade quando essa parte for feita.
class TelaTeste extends StatelessWidget {
  const TelaTeste({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('App Financeiro')),
      body: Center(
        child: Text('Provider funcionando! Contador: ${appState.contador}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<AppState>().incrementar(),
        child: const Icon(Icons.add),
      ),
    );
  }
}